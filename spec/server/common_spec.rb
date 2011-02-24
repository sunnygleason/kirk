require 'spec_helper'

describe "Common things" do
  it "is not in a subprocess by default" do
    Kirk.sub_process?.should be_false
  end
end
