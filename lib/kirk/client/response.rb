class Kirk::Client
  class Response
    attr_accessor :version, :status, :body, :headers, :exception

    def initialize(buffer_body)
      @status       = nil
      @version      = nil
      @headers      = {}
      @buffer_body  = buffer_body
      @body         = buffer_body ? "" : nil
      @exception    = nil
    end

    def buffer_body?
      @buffer_body
    end

    def success?
      @status && @status < 400 && !@exception
    end

    def exception?
      @exception
    end
  end
end
