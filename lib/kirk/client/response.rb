class Kirk::Client
  class Response
    attr_accessor :version, :status, :body, :headers

    def initialize(buffer_body)
      @status, @version, @headers = nil, nil, {}
      @buffer_body = buffer_body

      @body = buffer_body ? "" : nil
    end

    def buffer_body?
      @buffer_body
    end
  end
end
