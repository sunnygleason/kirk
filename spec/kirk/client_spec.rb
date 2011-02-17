require 'spec_helper'
require 'kirk/client'

describe 'Kirk::Client' do
  describe "simple get" do
    before do
      @env = nil
      start(lambda do |env|
        [ 200, { 'Content-Type' => 'text/plain'}, [ env['PATH_INFO'] ] ]
      end)
    end

    it "performs simple GET" do
      group = Kirk::Client.group do |s|
        s.request :GET, "http://localhost:9090/"
      end

      group.should have(1).responses
      group.responses.first.content.should == "/"
    end

    it "performs more than one GET" do
      group = Kirk::Client.group do |s|
        s.request :GET, "http://localhost:9090/foo"
        s.request :GET, "http://localhost:9090/bar"
      end

      group.should have(2).responses
      group.responses.map(&:content).sort.should == %w(/bar /foo)
    end
  end

  it "allows to stream body" do
    handler = Class.new do
      def initialize(buffer)
        @buffer = buffer
      end

      def on_response_content(content)
        @buffer << content
      end
    end

    start(lambda do |env|
      [ 200, { 'Content-Type' => 'text/plain' }, [ "a" * 10000 ] ]
    end)

    @buffer = []

    group = Kirk::Client.group do |s|
      s.request :GET, "http://localhost:9090/", handler.new(@buffer)
    end

    group.should have(1).responses
    @buffer.length.should be > 1
  end

  context "callbacks" do
    it "handles on_response_complete callback" do
      handler = Class.new do
        def initialize(buffer)
          @buffer = buffer
        end

        def on_response_complete(response)
          @buffer << response
        end
      end

      start_default_app

      @buffer = []
      group = Kirk::Client.group do |s|
        s.request :GET, "http://localhost:9090/", handler.new(@buffer)
      end

      @buffer.first.should == group.responses.first
    end
  end

  def start_default_app
    start(lambda { |env| [ 200, { 'Content-Type' => 'text/plain' }, [ "Hello" ] ] })
  end
end
