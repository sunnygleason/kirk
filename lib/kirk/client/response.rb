class Kirk::Client
  class Response
    attr_reader :status, :body, :headers

    def initialize(body, status, headers)
      @body    = body
      @status  = status
      @headers = headers
    end
  end
end
