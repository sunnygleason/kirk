module Kirk
  module Applications
    class Config
      include Native::ApplicationConfig

      attr_accessor :env,
                    :hosts,
                    :listen,
                    :watch,
                    :rackup,
                    :application_path,
                    :bootstrap_path

      def initialize
        @env    = {}
        @hosts  = []
        @listen = listen
      end

      def application_path
        @application_path || File.dirname(rackup)
      end

      # Handle the java interface
      alias getApplicationPath    application_path
      alias getRackupPath         rackup
      alias getBootstrapPath      bootstrap_path

      def getEnvironment
        map = java.util.HashMap.new
        env = ENV.dup

        self.env.each do |key, val|
          env[key.to_s] = val
        end

        env.each do |key, val|
          next unless val

          key = key.to_java_string
          val = val.to_s.to_java_string

          map.put(key, val)
        end

        map
      end
    end
  end
end
