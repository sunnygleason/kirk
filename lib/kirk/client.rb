require 'kirk'

module Kirk
  class Client
    import java.net.InetSocketAddress
    import java.util.concurrent.LinkedBlockingQueue
    import java.util.concurrent.AbstractExecutorService
    import java.util.concurrent.TimeUnit
    import java.util.concurrent.ThreadPoolExecutor
    import java.util.concurrent.ExecutorCompletionService

    class << self
      def group(opts = {})
        new.group(opts, &Proc.new)
      end
    end

    def group(opts = {})
      group = Group.new(self, opts)
      group.start(&Proc.new)
      group
    end

    def initialize(opts = {})
      client.set_thread_pool(opts.delete(:thread_pool)) if opts[:thread_pool]
    end

    def client
      @client ||= begin
        client = Jetty::HttpClient.new
        client.set_connector_type(Jetty::HttpClient::CONNECTOR_SELECT_CHANNEL)
        client.start
        client
      end
    end

    def process(request)
      exchange = Exchange.from_request(request)
      client.send(exchange)
    end
  end
end

require 'kirk/client/group'
require 'kirk/client/response'
require 'kirk/client/request'
require 'kirk/client/exchange'
