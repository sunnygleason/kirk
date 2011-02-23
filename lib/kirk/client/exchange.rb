module Kirk
  class Client
    class Exchange < Jetty::ContentExchange

      def self.from_request(req)
        new.tap do |inst|
          inst.group    = req.group
          inst.handler  = req.handler
          inst.method   = req.method
          inst.url      = req.url

          if req.headers
            req.headers.each do |name, val|
              inst.set_request_header(name, val)
            end
          end

          if req.body
            #
            # If the body is already an InputStream (thus in the correct
            # format), just run with it.
            if Java::JavaIo::InputStream === req.body
              inst.request_content_source = req.body
            #
            # If the body responds to the JRuby method that converts
            # an object to an InputStream, then use that
            elsif req.body.respond_to?(:to_inputstream)
              inst.request_content_source = req.body.to_inputstream
            #
            # If it responds to :read but not to :to_inputstream, then
            # it is a ruby object that is trying to look like an IO but
            # hasn't implemented the magic JRuby conversion method, so
            # we have to make it work.
            #
            # XXX Implement an InputStream subclass that can wrap ruby
            # IO like objects
            elsif req.body.respond_to?(:read)
              inst.request_content = bufferize(req.body.read)
            #
            # The fallback plan is to just call #to_s on the object
            else
              inst.request_content = bufferize(req.body.to_s)
            end
          end
        end
      end

      def self.bufferize(obj)
        Jetty::ByteArrayBuffer.new(obj.to_s)
      end

      attr_accessor :group, :handler

      def initialize
        @headers = {}
      end

      def on_exception(ex)
        puts ex.inspect
      end

      def on_response_complete
        @group.queue.put(response)
        handle(:on_response_complete, response)
        super
      end

      def on_response_content(content)
        handle(:on_response_content, content)
        super
      end

      def on_response_header(name, value)
        @headers[name.to_s] = value.to_s
        handle(:on_response_header, {name.to_s => value.to_s})
        super
      end

      def response
        @response ||= begin
          Response.new(get_response_content, get_response_status, @headers)
        end
      end

      def handle(method, *args)
        @handler.send(method, *args) if @handler && @handler.respond_to?(method)
      end

      # Implement Java API
      alias onResponseComplete on_response_complete
      alias onResponseContent  on_response_content
      alias onResponseHeader   on_response_header
      alias onException        on_exception
    end
  end
end
