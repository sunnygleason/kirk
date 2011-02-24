# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'kirk/version'

Gem::Specification.new do |s|
  s.name        = "kirk"
  s.version     = Kirk::VERSION
  s.platform    = "java"
  s.authors     = ["Carl Lerche"]
  s.email       = ["me@carllerche.com"]
  s.homepage    = "http://github.com/strobecorp/kirk"
  s.summary     = "A JRuby Rack Server Based on Jetty"

  s.description = <<-DESCRIPTION
Kirk is a wrapper around Jetty that hides all of the insanity and
wraps your Rack application in a loving embrace. Also, Kirk is
probably one of the least HTTP retarded ruby rack server out there.
  DESCRIPTION

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "kirk"

  s.files = Dir["lib/**/*.{rb,jar}"] +
            ["bin/kirk", "README.md", "LICENSE"]

  s.executables        = %w(kirk)
  s.default_executable = "kirk"
  s.require_paths      = ["lib"]
end
