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
      @session.queue.offer(response)
      @handler.on_response_complete(response) if @handler
    end

    def response
      @response = begin
                    Response.new(get_response_content, get_response_status)
                  end
    end

    def self.from_request(request)
      exchange = new(request.session, request.handler)
      exchange.set_method(request.method)
      exchange.set_url(request.url)
      exchange
    end
  end
end
