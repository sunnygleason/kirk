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
      session = Kirk::Client.session do |s|
        s.request :GET, "http://localhost:9090/"
      end

      session.should have(1).responses
      session.responses.first.content.should == "/"
    end

    it "performs more than one GET" do
      session = Kirk::Client.session do |s|
        s.request :GET, "http://localhost:9090/foo"
        s.request :GET, "http://localhost:9090/bar"
      end

      session.should have(2).responses
      session.responses.map(&:content).sort.should == %w(/bar /foo)
    end
  end

  it "allows to stream body" do
    class MyHandler
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

    session = Kirk::Client.session do |s|
      s.request :GET, "http://localhost:9090/", MyHandler.new(@buffer)
    end

    session.should have(1).responses
    @buffer.length.should be > 1
  end

end
