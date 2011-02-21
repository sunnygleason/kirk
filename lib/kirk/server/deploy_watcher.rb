require 'socket'

module Kirk
  class Server::DeployWatcher
    include Jetty::LifeCycle::Listener

    def initialize(unix_socket_path = nil)
      @apps, @magic_telephone, @workers = [], LinkedBlockingQueue.new, 0
      @unix_socket, @unix_socket_path = nil, unix_socket_path
      @info = {}
    end

    def start
      raise "Watcher already started" if @thread
      connect_unix_socket_server
      @thread = Thread.new { run_loop }
      @thread.abort_on_exception = true
      true
    end

    def stop
      @magic_telephone.put :halt

      disconnect_unix_socket_server

      @thread.join
      @thread = nil
      true
    end

    def life_cycle_started(app)
      @magic_telephone.put [ :watch, app ]
    end

    def life_cycle_stopping(app)
      @magic_telephone.put [ :unwatch, app ]
    end

    # Rest of the java interface
    def life_cycle_failure(app, cause)  ; end
    def life_cycle_starting(app)        ; end
    def life_cycle_stopped(app)         ; end

  private

    def connect_unix_socket_server
      return unless @unix_socket_path

      umask = File.umask
      File.umask(0137)

      if File.exist?(@unix_socket_path)
        File.delete(@unix_socket_path)
      end

      @unix_socket = UNIXServer.new(@unix_socket_path)
    ensure
      File.umask(umask)
    end

    def disconnect_unix_socket_server
      @unix_socket.close if @unix_socket
      File.delete(@unix_socket_path) if @unix_socket_path
    end

    def run_loop
      while true
        # First, check if there are any pending connections
        handle_redeploys_on_socket

        # Then, pull off messages
        while msg = @magic_telephone.poll(50, TimeUnit::MILLISECONDS)
          return if msg == :halt
          handle_message(*msg)
        end

        check_apps
      end

      until @workers == 0
        msg = @magic_telephone.take
        handle_message(*msg)
      end

      cleanup
    end

    def handle_redeploys_on_socket
      return unless @unix_socket

      conn = @unix_socket.accept_nonblock
      line = conn.gets.chomp

      if line =~ /^REDEPLOY (.*)$/
        rackup_path = $1
        app = @apps.find { |a| a.rackup_path == rackup_path }

        unless app
          conn.write "ERROR No application racked up at `#{rackup_path}`\n"
          return
        end

        conn.write "INFO Redeploying application...\n"

        if redeploy(app)
          conn.write "INFO Redeploy complete.\n"
        else
          conn.write "ERROR Something went wrong\n"
        end
      else
        conn.write "ERROR unknown command\n"
      end
    rescue Errno::EAGAIN,
           Errno::EWOULDBLOCK,
           Errno::ECONNABORTED,
           Errno::EPROTO,
           Errno::EINTR
      # Nothing
    ensure
      conn.close if conn
    end

    def handle_message(action, *args)
      case action
      when :watch

        app, _ = *args

        @apps |= [app]

        @info[app] ||= {
          :standby       => LinkedBlockingQueue.new,
          :last_modified => app.last_modified
        }

        warmup_standby_deploy(app)

      when :unwatch

        app, _ = *args
        @apps.delete(app)

      when :worker_complete

        @workers -= 1

      else

        raise "Unknown action `#{action}`"

      end
    end

    def check_apps
      @apps.each do |app|
        new_last_modified = app.last_modified
        info = @info[app]

        next unless new_last_modified

        if new_last_modified > info[:last_modified]
          Kirk.logger.info("Reloading `#{app.rackup_path}`")

          # Redeploy the application
          redeploy(app)

          # Update the last modified time
          info[:last_modified] = new_last_modified
        end
      end
    end

    def redeploy(app)
      ret = app.deploy(get_standby_deploy(app))
      warmup_standby_deploy(app)
      ret
    end

    def get_standby_deploy(app)
      queue = @info[app][:standby]
      key   = app.key

      return unless key

      while deploy = queue.poll
        return deploy if deploy.key == key
        # Otherwise, we don't need it anymore
        background { deploy.terminate }
      end
    end

    def warmup_standby_deploy(app)
      queue = @info[app][:standby]

      return unless queue.size == 0

      background do
        deploy = app.build_deploy
        queue.put deploy if deploy
      end
    end

    def cleanup
      @apps.each do |app|
        queue = @info[app][:standby]

        while deploy = queue.poll
          deploy.terminate
        end
      end
    end

    def background
      @workers += 1
      Thread.new do
        yield
        @magic_telephone.put [ :worker_complete ]
      end
    end
  end
end
