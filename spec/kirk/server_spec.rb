require 'spec_helper'

describe 'Kirk::Server' do
  it "runs a simple rack application" do
    start lambda { |env| [ 200, { 'Content-Type' => "text/plain" }, [ "Hello Rack" ] ] }

    get '/'
    last_response.should be_successful
    last_response.should have_body("Hello Rack")
  end
  it "runs the server" do
    start hello_world_path('config.ru')

    get '/'
    last_response.should be_successful
    last_response.should have_body('Hello World')
  end

  it "runs the server on the specified port" do
    path = hello_world_path('config.ru')

    start do
      log :level => :warning

      rack "#{path}" do
        listen 9091
      end
    end

    host! 'localhost', 9091

    get '/'
    last_response.should be_successful
    last_response.should have_body('Hello World')
  end

  it "can start multiple applications" do
    path1 = hello_world_path('config.ru')
    path2 = goodbye_world_path('config.ru')

    start do
      log :level => :warning

      rack "#{path1}" do
        listen '127.0.0.1:9090'
      end

      rack "#{path2}" do
        listen ':9090'
      end
    end

    get '/'
    last_response.should be_successful
    last_response.should have_body('Hello World')

    host! IP_ADDRESS, 9090

    get '/'
    last_response.should have_body('Goodbye World')
  end

  it "can start multiple applications on the same port" do
    path1 = hello_world_path('config.ru')
    path2 = goodbye_world_path('config.ru')

    start do
      log :level => :warning

      rack "#{path1}" do
        listen '127.0.0.1:9090'
      end

      rack "#{path2}" do
        listen '127.0.0.1:9090'
      end
    end

    get '/'
    last_response.should be_successful
    last_response.should have_body('Hello World')
  end

  it "can partition applications by the host name" do
    path1 = hello_world_path('config.ru')
    path2 = goodbye_world_path('config.ru')

    start do
      log :level => :warning

      rack "#{path1}" do
        hosts 'foo.com', 'bar.com'
      end

      rack "#{path2}" do
        hosts 'baz.com'
      end
    end

    get '/', {}, 'HTTP_HOST' => 'foo.com'
    last_response.should have_body('Hello World')

    get '/', {}, 'HTTP_HOST' => 'bar.com'
    last_response.should have_body('Hello World')

    get '/', {}, 'HTTP_HOST' => 'baz.com'
    last_response.should have_body('Goodbye World')

    get '/', {}, 'HTTP_HOST' => 'localhost'
    last_response.should be_missing
  end


  it "reloads the server" do
    start randomized_app_path('config.ru')

    get '/'
    num = last_response.body

    get '/'
    last_response.body.should == num

    touch randomized_app_path('REVISION')
    # Gives the server the time to see the
    # revision change and reload the app
    sleep 2

    get '/'
    last_response.body.should_not == num
  end

  it "can watch a specified file to trigger redeploys" do
    path = randomized_app_path('config.ru')

    start do
      log :level => :warning

      rack "#{path}" do
        watch "redeploy.txt"
      end
    end

    get '/'
    num = last_response.body

    touch randomized_app_path('redeploy.txt')
    sleep 2

    get '/'
    last_response.body.should_not == num
  end

  it "can load config files relative to the current file" do
    kirkup kirked_up_path("Kirkfile")

    get '/'
    last_response.should have_body('Hello World')

    host! 'localhost', 9091

    get '/'
    last_response.should have_body('Goodbye World')
  end

  it "can rackup applications that don't use config.ru as the rackup file" do
    start blacksheep_path('not_config.ru')

    get '/'
    last_response.should be_successful
    last_response.should have_body("Black Sheep")
  end

  it "provides a friendly error when the file being loaded doesn't exist" do
    lambda do
      start do
        load "zomgHI2U"
      end
    end.should raise_error(Kirk::MissingConfigFile)
  end
end
