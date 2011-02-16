class Kirk::Client
  class Request
    attr_reader :method, :path, :handler

    def initialize(session, method, url, handler, headers)
      @session = session
      @method  = method.to_s.upcase
      @url     = url
      @handler = handler
    end

    def exchange
      @exchange = begin
                    exchange = Exchange.new(@session, @handler)
                    exchange.set_method(method)
                    exchange.set_url(@url)
                    exchange
                  end
    end
  end
end
