class Kirk::Client
  class Response
    attr_reader :status, :content

    def initialize(content, status)
      @content = content
      @status  = status
    end
  end
end
