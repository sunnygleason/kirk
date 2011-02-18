class Kirk::Client
  class Response
    attr_reader :status, :body

    def initialize(body, status)
      @body = body
      @status  = status
    end
  end
end
