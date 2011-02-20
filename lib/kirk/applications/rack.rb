gem "rack", ">= 1.0.0"
require "rack"

module Kirk
  module Applications
    # This class extends a native Java class
    class Rack < Jetty::AbstractHandler
      def self.new(app)
        inst     = super()
        inst.app = Server::Handler.new(app)
        inst
      end

      attr_accessor :app

      def handle(target, base_request, request, response)
        app.handle(target, base_request, request, response)
      end
    end
  end
end
