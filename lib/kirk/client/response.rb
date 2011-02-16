class Kirk::Client
  class Response
    attr_reader :status

    def initialize(content, status)
      @content = content
      @status  = status
    end
  end
end
