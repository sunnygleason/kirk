require 'spec_helper'

describe "Kirk CLI interface" do
  it "reads the configuration file, starts kirk, then redeploys" do
    kirk "-c #{kirked_up_path}/Kirkfile" do |c|
      c.stdout.gets.should =~ /INFO - jetty/
      while (output = c.stdout.gets) =~ /INFO - started o\.e\.j\.s\.h\.ContextHandler/; end
      output.should =~ /INFO - Started SelectChannelConnector@0\.0\.0\.0:9090/

      get '/'
      last_response.should be_successful
      last_response.should have_body('Hello World')

      File.open(hello_world_path('config.ru'), 'w') do |f|
        f.puts <<-RUBY
          run lambda { |e| [ 200, { 'Content-Type' => 'text/plain' }, [ 'Hello World 2' ] ] }
        RUBY
      end

      get '/'
      last_response.should be_successful
      last_response.should have_body('Hello World')

      kirk "redeploy -R #{hello_world_path('config.ru')}" do |c2|
        c2.stdout.gets.should =~ /Waiting for response.../
        c2.stdout.gets.should =~ /Redeploying application.../
        c2.stdout.gets.should =~ /Redeploy complete./
      end

      get '/'
      last_response.should have_body('Hello World 2')
    end
  end

  it "exits with an error if the config file does not exist" do
    kirk do |c|
      c.stderr.read.chomp.should =~ /\[ERROR\] config file `.*?\/Kirkfile` does not exist/
    end

    last_command.exit_status.should == 1
  end
end
