class Kirk::Client
  class Request
    attr_reader :method, :url, :handler, :group

    def initialize(group, method, url, handler, headers)
      @group = group
      @method  = method.to_s.upcase
      @url     = url
      @handler = handler
    end
  end
end
