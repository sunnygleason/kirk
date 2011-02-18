class Kirk::Client
  class Request
    attr_reader :method, :url, :handler, :group, :headers

    def initialize(group, method, url, headers, handler)
      @group = group
      @method  = method.to_s.upcase
      @url     = url
      @handler = handler
      @headers = headers
    end
  end
end
