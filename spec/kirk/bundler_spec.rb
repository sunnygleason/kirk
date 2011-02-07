require 'spec_helper'

describe "Kirk bundler integration" do
  it "doesn't require 'bundler/setup' if there is no Gemfile" do
    start require_as_app_path('config.ru')

    get '/'
    last_response.should be_successful
    last_response.should have_body('ActiveSupport')
  end

  it "requires 'bundler/setup' if there is a Gemfile" do
    start bundled_app_path('config.ru')

    get '/'
    last_response.should be_successful
    last_response.should have_body("required ActiveSupport\n" \
                                   "failed to load Rake\n")
  end

  it "doesn't use stale standby instances" do
    start bundled_app_path('config.ru')

    get '/'
    last_response.should have_body("required ActiveSupport\n" \
                                   "failed to load Rake\n")

    sleep 2

    File.open bundled_app_path('Gemfile'), 'w' do |f|
      f.puts <<-GEMFILE
        source 'http://rubygems.org'

        gem 'rack'
        gem 'rake'
        gem 'activesupport'
      GEMFILE
    end

    touch bundled_app_path('REVISION')

    sleep 2

    get '/'
    last_response.should have_body("required ActiveSupport\n" \
                                   "successfully loaded Rake\n")
  end

  it "doesn't take down the live application if something goes wrong when starting a redeploy" do
    start bundled_app_path('config.ru')

    get '/'

    File.open bundled_app_path('Gemfile'), 'w' do |f|
      f.puts <<-GEMFILE
        source 'http://rubygems.org'

        gem 'rack'
        gem 'rake'
        gem 'activesupport'
        gem 'fail'
      GEMFILE
    end

    touch bundled_app_path('REVISION')

    sleep 2

    get '/'
    last_response.should have_body("required ActiveSupport\n" \
                                   "failed to load Rake\n")
  end
end
