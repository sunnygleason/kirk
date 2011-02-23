module Kirk
  class Client
    class Exchange < Jetty::ContentExchange
      def initialize(session, handler)
        @handler = handler
        @session = session
        @headers = {}
        super()
      end

      def on_exception(ex)
        puts ex.inspect
      end

      def on_response_complete
        @session.queue.put(response)
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

      def self.from_request(request)
        exchange = new(request.group, request.handler)
        exchange.set_method(request.method)
        exchange.set_url(request.url)
        request.headers.each do |name, value|
          exchange.set_request_header(name, value)
        end if request.headers
        if request.body && request.body.respond_to?(:read)
          exchange.set_request_content_source(request.body.to_inputstream)
        else
          body = Jetty::ByteArrayBuffer.new(request.body.to_s)
          exchange.set_request_content(body)
        end
        exchange
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
