module Kirk
  class Client
    import org.eclipse.jetty.client.HttpClient
    import org.eclipse.jetty.client.HttpExchange
    import java.net.InetSocketAddress
    import java.util.concurrent.LinkedBlockingQueue
    import org.eclipse.jetty.client.ContentExchange
    import java.util.concurrent.AbstractExecutorService
    import java.util.concurrent.TimeUnit
    import java.util.concurrent.ThreadPoolExecutor
    import java.util.concurrent.ExecutorCompletionService

    def self.session
      Session.new(&Proc.new)
    end

    private
  end
end

require 'kirk/client/session'
require 'kirk/client/response'
require 'kirk/client/request'
require 'kirk/client/connection'
require 'kirk/client/exchange'
