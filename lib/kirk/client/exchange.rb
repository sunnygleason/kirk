class Kirk::Client
  class Exchange < ContentExchange
    include java.util.concurrent.Callable

    def initialize(session, handler)
      @handler = handler
      @session = session
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
      request.headers.each do |name, value|
        exchange.set_request_header(name, value)
      end if request.headers
      exchange
    end

    def handle(method, *args)
      @handler.send(method, *args) if @handler && @handler.respond_to?(method)
    end

    alias onResponseComplete on_response_complete
    alias onResponseContent  on_response_content
    alias onResponseHeader   on_response_header
    alias onException        on_exception
  end
end
