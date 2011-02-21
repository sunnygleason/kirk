require 'uri'

module Kirk
  class Client
    class Group

      attr_reader :responses, :queue, :block, :client
      alias :block? :block

      def initialize(client = Client.new, options = {})
        @block = options.include?(:block) ? options[:block] : true
        @options = options
        fetch_host
        @queue = LinkedBlockingQueue.new
        @client = client
        @requests_count = 0
        @responses = []
      end

      def start
        @thread = Thread.new do
          yield(self)

          get_responses
        end

        join if block?
      end

      def join
        @thread.join
      end

      def complete
        @complete = Proc.new if block_given?
        @complete
      end

      def request(method = nil, url = nil, handler = nil, headers = {})
        request = Request.new(self, method, url, handler, headers)
        yield request if block_given?
        request.url URI.join(@host, request.url).to_s if @host
        queue_request(request)
        request
      end

      %w/get post put delete/.each do |method|
        class_eval <<-RUBY
          def #{method}(url, headers = nil, handler = nil)
            request(:#{method.upcase}, url, headers, handler)
          end
        RUBY
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

        completed
      end

    private

      def completed
        complete.call if complete
      end

      def fetch_host
        if @options[:host]
          @host = @options.delete(:host).chomp('/')
          @host = "http://#{@host}" unless @host =~ /^https?:\/\//
        end
      end
    end
  end
end
