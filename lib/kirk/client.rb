require 'kirk'

module Kirk
  class Client
    require 'kirk/client/group'
    require 'kirk/client/response'
    require 'kirk/client/request'
    require 'kirk/client/exchange'

    def self.group(opts = {})
      new.group(opts, &Proc.new)
    end

    def group(opts = {}, &blk)
      Group.new(self, opts).tap do |group|
        group.start(&blk)
      end
    end

    def initialize(opts = {})
      client.set_thread_pool(opts.delete(:thread_pool)) if opts[:thread_pool]
    end

    def client
      @client ||= Jetty::HttpClient.new.tap do |client|
        client.set_connector_type(Jetty::HttpClient::CONNECTOR_SELECT_CHANNEL)
        client.start
      end
    end

    def process(request)
      exchange = Exchange.from_request(request)
      client.send(exchange)
    end
  end
end
