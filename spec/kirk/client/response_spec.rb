require 'spec_helper'

describe Kirk::Client::Response do
  it "allows to pass body, status and headers" do
    response = Kirk::Client::Response.new("body", 200, {'Content-Type' => 'text/plain'})
    response.body.should    == "body"
    response.headers.should == {'Content-Type' => 'text/plain'}
    response.status.should  == 200
  end
end
