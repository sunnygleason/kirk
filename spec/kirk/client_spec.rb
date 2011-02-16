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

end
