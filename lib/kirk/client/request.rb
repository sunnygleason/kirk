class Kirk::Client
  class InvalidRequestError < ArgumentError ; end

  class Request
    attr_reader :group

    def initialize(group, method = nil, url = nil, handler = nil, body = nil, headers = {})
      @group    = group
      @url      = url
      @handler  = handler
      @body     = body
      @headers  = headers
      @method   = normalize_method(method)

      self.headers.merge!(Kirk::REQUEST_INFO.get) if Kirk::REQUEST_INFO.get

      yield self if block_given?
    end

    %w/url headers handler body/.each do |method|
      class_eval <<-RUBY
        def #{method}(*args)
          @#{method} = args.first unless args.empty?
          @#{method}
        end
      RUBY
    end

    def method(*args)
      @method = normalize_method(args.first) unless args.empty?
      @method
    end

    def validate!
      unless method
        raise InvalidRequestError, "Must specify an HTTP method for the request"
      end

      unless url
        raise InvalidRequestError, "Must specify a URL for the request"
      end
    end

  private

    def normalize_method(method)
      method.to_s.upcase if method
    end
  end
end
