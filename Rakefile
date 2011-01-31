require 'ant'

directory 'build'
directory 'build/kirk'
directory 'build/kirk/classes'

FILES = Dir['src/**/*.java']

def class_path
  Dir['lib/kirk/jetty/*.jar'].join(':')
end

desc 'Compile the library'
task :compile => ['build/kirk/classes'] + FILES do |t|
  ant.property :name => "build.sysclasspath", :value => "ignore"
  ant.javac :srcdir => "src", :destdir => t.prerequisites.first,
    :debug => true, :source => "1.5", :target => "1.5",
    :classpath => "#{class_path}:${java.class.path}:${sun.boot.class.path}"
end

desc 'Build the Jar'
task :jar => :compile do
  ant.jar :basedir => "build/kirk/classes", :destfile => "build/kirk/native.jar",
    :includes => "**/*.class"

  cp "build/kirk/native.jar", "lib/kirk/native.jar"
end

desc 'Clean up build artifacts'
task :clean do
  rm_rf 'build'
end

desc 'Run specs'
task :spec => :jar do
  sh "ruby -S rspec spec"
end

desc 'Package the gem'
task :gem => :jar do
  sh "ruby -S gem build kirk.gemspec"
end

task :default => :spec
