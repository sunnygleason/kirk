class Kirk::Client
  class Exchange < HttpExchange
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
      raise "Response is not ready yet" unless is_done
      @response = begin
                    Response.new(get_content, get_status)
                  end
    end

    def is_canceled
      get_status == STATUS_CANCELLED
    end

    def call
      self
    end
  end
end
