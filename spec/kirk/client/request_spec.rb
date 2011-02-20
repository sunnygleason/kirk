require 'spec_helper'

describe Kirk::Client::Request do
  it "allows to pass method, url, headers and handler" do
    handler = Object.new
    group   = Kirk::Client::Group.new
    request = Kirk::Client::Request.new(group, :GET, "http://localhost",
                                        handler, {'Accept' => 'text/javascript'})

    request.method.should  == "GET"
    request.url.should     == "http://localhost"
    request.headers.should == {'Accept' => 'text/javascript'}
    request.handler.should == handler
  end

  it "allows to pass a block to set all the args on the instance" do
    handler = Object.new
    body    = StringIO.new

    request = Kirk::Client::Request.new(Kirk::Client::Group.new) do |r|
      r.method  :post
      r.url     "http://localhost"
      r.headers 'Accept' => 'text/javascript'
      r.handler handler
      r.body    body
    end

    request.method.should  == "POST"
    request.url.should     == "http://localhost"
    request.headers.should == {'Accept' => 'text/javascript'}
    request.handler.should == handler
    request.body.should    == body
  end

end
