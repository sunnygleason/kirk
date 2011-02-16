class Kirk::Client
  class Request
    attr_reader :method, :url, :handler, :session

    def initialize(session, method, url, handler, headers)
      @session = session
      @method  = method.to_s.upcase
      @url     = url
      @handler = handler
    end
  end
end
