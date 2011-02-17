class Kirk::Client
  class Group

    attr_reader :responses, :queue

    def initialize
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

    def request(method, url, handler = nil, headers = nil)
      request = Request.new(self, method, url, handler, headers)
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
  end
end
