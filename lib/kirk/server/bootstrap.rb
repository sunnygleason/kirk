require 'java'

module Kirk
  SUB_PROCESS = true

  class Server
    class Bootstrap
      def warmup(application_path)
        Dir.chdir File.expand_path(application_path)

        load_rubygems

        load_bundle.tap do
          add_kirk_to_load_path

          load_rack
          load_kirk
        end
      end

      def run(rackup)
        app, options = Rack::Builder.parse_file(rackup)

        Handler.new(app)
      end

    private

      def load_rubygems
        require 'rubygems'
      end

      def load_bundle
        if File.exist?('Gemfile')
          require 'bundler/setup'

          if File.exist?('Gemfile.lock')
            require 'digest/sha1'
            str = File.read('Gemfile') + File.read('Gemfile.lock')
            Digest::SHA1.hexdigest(str)
          end
        end
      end

      def add_kirk_to_load_path
        $:.unshift File.expand_path('../../..', __FILE__)
      end

      def load_rack
        gem "rack", ">= 1.0.0"
        require 'rack'
      end

      def load_kirk
        require 'kirk/version'
        require 'kirk/common'
        require 'kirk/jetty'
        require 'kirk/server/input_stream'
        require 'kirk/server/handler'
      end
    end
  end
end

Kirk::Server::Bootstrap.new
