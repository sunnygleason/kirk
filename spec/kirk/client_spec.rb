require 'spec_helper'
require 'kirk/client'

import org.eclipse.jetty.util.thread.QueuedThreadPool

describe 'Kirk::Client' do

  describe "requests" do
    before do
      start echo_app_path('config.ru')
    end

    it "performs simple GET" do
      group = Kirk::Client.group do |s|
        s.request :GET, "http://localhost:9090/"
      end

      group.should have(1).responses
      response = parse_response(group.responses.first)
      response["PATH_INFO"].should == "/"
      response["REQUEST_METHOD"].should == "GET"
    end

    it "performs more than one GET" do
      group = Kirk::Client.group do |s|
        s.request :GET, "http://localhost:9090/foo"
        s.request :GET, "http://localhost:9090/bar"
      end

      group.should have(2).responses
      parse_responses(group.responses).map { |r| r["PATH_INFO"] }.sort.should == %w(/bar /foo)
    end

    it "performs POST request" do
      group = Kirk::Client.group do |g|
        g.request :POST, "http://localhost:9090/", {'Accept' => 'text/html'}
      end

      response = parse_response(group.responses.first)
      response["HTTP_ACCEPT"].should == "text/html"
      response["REQUEST_METHOD"].should == "POST"
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
      s.request :GET, "http://localhost:9090/", {}, handler.new(@buffer)
    end

    sleep(0.05)
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
        s.request :GET, "http://localhost:9090/", {}, handler.new(@buffer)
      end

      sleep(0.05)
      @buffer.first.should == group.responses.first
    end

    it "handles on_response_header callback" do
      handler = Class.new do
        def initialize(buffer)
          @buffer = buffer
        end

        def on_response_header(headers)
          @buffer << headers
        end
      end

      start_default_app

      @buffer = []
      group = Kirk::Client.group do |s|
        s.request :GET, "http://localhost:9090/", {}, handler.new(@buffer)
      end

      sleep(0.05)
      @buffer.first.should == {'Content-Type' => 'text/plain'}
    end
  end

  it "allows to set thread_pool" do
    thread_pool = QueuedThreadPool.new
    client = Kirk::Client.new(:thread_pool => thread_pool)
    client.client.get_thread_pool.should == thread_pool
  end

  it "allows to run group on instance" do
    start_default_app

    client = Kirk::Client.new
    result = client.group do |g|
      g.request :GET, "http://localhost:9090/"
    end

    result.responses.first.body.should == "Hello"
  end

  it "allows to set host for group" do
    start_default_app

    group = Kirk::Client.group(:host => "localhost:9090") do |g|
      g.request :GET, "/"
    end

    group.responses.first.body.should == "Hello"
  end

  def start_default_app
    start(lambda { |env| [ 200, { 'Content-Type' => 'text/plain' }, [ "Hello" ] ] })
  end

  def parse_response(response)
    Marshal.load(response.body)
  end

  def parse_responses(responses)
    responses.map { |r| parse_response(r) }
  end
end
