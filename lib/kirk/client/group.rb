require 'uri'

class Kirk::Client
  class Group

    attr_reader :responses, :queue

    def initialize(options = {})
      @options = options
      fetch_host
      @queue = LinkedBlockingQueue.new
      @client = Kirk::Client.new
      @requests_count = 0
      @responses = []
    end

    def start
      yield(self)

      # TODO: do not block by default
      get_responses
    end

    def request(method, url, headers = nil, handler = nil)
      url = URI.join(@host, url).to_s if @host
      request = Request.new(self, method, url, headers, handler)
      yield request if block_given?
      queue_request(request)
      request
    end

    def queue_request(request)
      @client.process(request)
      @requests_count += 1
    end

    def get_responses
      while @requests_count > 0
        @responses << @queue.take
        @requests_count -= 1
      end
    end

    private

    def fetch_host
      if @options[:host]
        @host = @options.delete(:host).chomp('/')
        @host = "http://#{@host}" unless @host =~ /^https?:\/\//
      end
    end
  end
end
