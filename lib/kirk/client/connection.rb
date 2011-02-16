class Kirk::Client
  class Connection
    attr_reader :request

    def initialize
      @request = nil
      @writing = false
      @client = HttpClient.new
      @client.set_connector_type(HttpClient::CONNECTOR_SELECT_CHANNEL);
      @client.start
    end

    def process(request)
      @client.send(request.exchange)
    end
  end
end
