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
      exchange = Exchange.from_request(request)
      @client.send(exchange)
    end
  end
end
