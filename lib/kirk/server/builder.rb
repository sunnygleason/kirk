module Kirk
  class MissingConfigFile < RuntimeError ; end
  class MissingRackupFile < RuntimeError ; end

  class Server
    class Builder

      VALID_LOG_LEVELS = %w(severe warning info config fine finer finest all)

      attr_reader :options

      def initialize(root = nil)
        @root    = root || Dir.pwd
        @current = nil
        @configs = []
        @options = {
          :watcher => DeployWatcher.new("/tmp/kirk.sock")
        }
      end

      def load(glob)
        glob = expand_path(glob)

        files = Dir[glob].select { |f| File.file?(f) }

        if files.empty?
          raise MissingConfigFile, "glob `#{glob}` did not match any files"
        end

        files.each do |file|
          with_root File.dirname(file) do
            instance_eval(File.read(file), file)
          end
        end
      end

      def log(opts = {})
        level = opts[:level]
        raise "Invalid log level" unless VALID_LOG_LEVELS.include?(level.to_s)
        @options[:log_level] = level.to_s
      end

      def rack(rackup)
        rackup = expand_path(rackup)

        unless File.exist?(rackup)
          raise MissingRackupFile, "rackup file `#{rackup}` does not exist"
        end

        @current = new_config
        @current.rackup = rackup

        yield if block_given?

      ensure
        @configs << @current
        @current = nil
      end

      def env(env)
        @current.env.merge!(env)
      end

      def hosts(*hosts)
        @current.hosts.concat hosts
      end

      def listen(*listeners)
        listeners = listeners.map do |listener|
          listener = listener.to_s
          listener = ":#{listener}"   unless listener.index(':')
          listener = "0.0.0.0#{listener}" if listener.index(':') == 0
          listener
        end

        @current.listen = listeners
      end

      def watch(*watch)
        @current.watch = watch
      end

      def to_handler
        handlers = @configs.map do |c|
          Jetty::ContextHandler.new.tap do |ctx|
            # Set the virtual hosts
            unless c.hosts.empty?
              ctx.set_virtual_hosts(c.hosts)
            end

            application = HotDeployable.new(c)
            application.add_watcher(watcher)

            ctx.set_connector_names c.listen
            ctx.set_handler application
          end
        end

        Jetty::ContextHandlerCollection.new.tap do |collection|
          collection.set_handlers(handlers)
        end
      end

      def to_connectors
        @connectors = {}

        @configs.each do |config|
          config.listen.each do |listener|
            next if @connectors.key?(listener)

            host, port = listener.split(':')

            connector = Jetty::SelectChannelConnector.new
            connector.set_host(host)
            connector.set_port(port.to_i)

            @connectors[listener] = connector
          end
        end

        @connectors.values
      end

    private

      def watcher
        @options[:watcher]
      end

      def with_root(root)
        old, @root = @root, root
        yield
      ensure
        @root = old
      end

      def expand_path(path)
        File.expand_path(path, @root)
      end

      def new_config
        ApplicationConfig.new.tap do |config|
          config.listen         = ['0.0.0.0:9090']
          config.watch          = [ ]
          config.bootstrap_path = File.expand_path('../bootstrap.rb', __FILE__)
        end
      end
    end
  end
end
