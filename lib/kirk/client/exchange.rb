module Kirk
  class Client
    class Exchange < Jetty::HttpExchange

      def self.build(request)
        inst = new
        inst.prepare! request
        inst
      end

      attr_accessor :request, :response

      def group
        request.group
      end

      def handler
        request.handler
      end

      def prepare!(request)
        self.request  = request
        self.response = Response.new(!handler.respond_to?(:on_response_body))
        self.method   = request.method
        self.url      = request.url

        if request.headers
          request.headers.each do |name, val|
            self.set_request_header(name.to_s, val.to_s)
          end
        end

        if request.body
          #
          # If the body is already an InputStream (thus in the correct
          # format), just run with it.
          if Java::JavaIo::InputStream === request.body
            self.request_content_source = request.body
          #
          # If the body responds to the JRuby method that converts
          # an object to an InputStream, then use that
          elsif request.body.respond_to?(:to_inputstream)
            self.request_content_source = request.body.to_inputstream
          #
          # If it responds to :read but not to :to_inputstream, then
          # it is a ruby object that is trying to look like an IO but
          # hasn't implemented the magic JRuby conversion method, so
          # we have to make it work.
          #
          # XXX Implement an InputStream subclass that can wrap ruby
          # IO like objects
          elsif request.body.respond_to?(:read)
            self.request_content = bufferize(request.body.read)
          #
          # The fallback plan is to just call #to_s on the object
          else
            self.request_content = bufferize(request.body.to_s)
          end
        end

        @buffer_body = handler.respond_to?(:on_response_content)
      end

      # Java callbacks
      #
      # def onConnectionFailed(ex)
      #   if handler.respond_to?(:on_connection_failed)
      #     handler.on_connection_failed(ex)
      #   end
      # end

      def onException(ex)
        if handler.respond_to?(:on_exception)
          handler.on_exception(ex)
        end

        response.exception = true
        group.respond(response)
      end

      # def onExpire
      #   # p [ :onExpire ]
      #   if handler.respond_to?(:on_timeout)
      #     handler.on_timeout
      #   end
      # end

      def onRequestComplete
        if handler.respond_to?(:on_request_complete)
          handler.on_request_complete
        end
      end

      def onResponseComplete
        if handler.respond_to?(:on_response_complete)
          handler.on_response_complete(response)
        end

        # Need to return the response after the handler
        # is done with it
        group.respond(response)
      end

      def onResponseContent(buf)
        chunk = stringify(buf)

        if handler.respond_to?(:on_response_body)
          handler.on_response_body(response, chunk)
        else
          response.body << chunk
        end
      end

      def onResponseHeader(name, value)
        response.headers[name.to_s] = value.to_s
      end

      def onResponseHeaderComplete
        if handler.respond_to?(:on_response_head)
          handler.on_response_head(response)
        end
      end

      def onResponseStatus(version, status, reason)
        response.status = status
      end

      def onRetry
        if handler.respond_to?(:on_retry)
          handler.on_retry
        end

        super
      end

      def onSwitchProtocol(end_point)
        # What is this exactly?
      end

    private

      def bufferize(obj)
        Jetty::ByteArrayBuffer.new(obj.to_s)
      end

      def stringify(buf)
        bytes = Java::byte[buf.length].new
        buf.get(bytes, 0, buf.length)
        String.from_java_bytes(bytes)
      end
    end
  end
end
