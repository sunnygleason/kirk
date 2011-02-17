class Kirk::Client
  class Exchange < ContentExchange
    include java.util.concurrent.Callable

    def initialize(session, handler)
      @handler = handler
      @session = session
      super()
    end

    def onException(ex)
      puts ex.inspect
    end

    def onResponseComplete
      @session.queue.put(response)
      handle(:on_response_complete, response)
      super
    end

    def onResponseContent(content)
      handle(:on_response_content, content)
      super
    end

    def onResponseHeader(name, value)
      handle(:on_response_header, {name.to_s => value.to_s})
      super
    end

    def response
      @response ||= begin
        Response.new(get_response_content, get_response_status)
      end
    end

    def self.from_request(request)
      exchange = new(request.group, request.handler)
      exchange.set_method(request.method)
      exchange.set_url(request.url)
      exchange
    end

    def handle(method, *args)
      @handler.send(method, *args) if @handler && @handler.respond_to?(method)
    end
  end
end
