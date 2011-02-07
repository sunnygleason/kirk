module Kirk
  class Applications::DeployWatcher
    include Jetty::LifeCycle::Listener

    def initialize
      @apps, @magic_telephone, @workers = [], LinkedBlockingQueue.new, 0
      @info = {}
    end

    def start
      raise "Watcher already started" if @thread
      @thread = Thread.new { run_loop }
      @thread.abort_on_exception = true
      true
    end

    def stop
      @magic_telephone.put :halt
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

    def run_loop
      while true
        # First, pull off messages
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

        if new_last_modified > info[:last_modified]
          Kirk.logger.info("Reloading `#{app.application_path}`")

          # Redeploy the application
          redeploy(app)

          # Update the last modified time
          info[:last_modified] = new_last_modified
        end
      end
    end

    def redeploy(app)
      app.deploy(get_standby_deploy(app))
      warmup_standby_deploy(app)
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
