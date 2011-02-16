require 'spec_helper'
require 'kirk/client'

describe 'Kirk::Client' do
  describe "simple get" do
    before do
      @env = nil
      start(lambda do |env|
        [ 200, { 'Content-Type' => 'text/plain'}, [ "a" ] ]
      end)
    end

    it "performs simple GET" do
      session = Kirk::Client.session do |s|
        s.request :GET, "http://localhost:9090/"
      end

      session.should have(1).responses
    end

    it "performs more than one GET" do
      session = Kirk::Client.session do |s|
        s.request :GET, "/foo"
        s.request :GET, "/bar"
      end

      session.should have(2).responses
    end
  end

end
