require 'kirk'
require 'optparse'

module Kirk
  class CLI
    def self.start(argv)
      new(argv).tap { |inst| inst.run }
    end

    def initialize(argv)
      @argv    = argv.dup
      @command = nil
      @options = default_options
    end

    def run
      parse!
      send(command_handler)
    rescue Exception => e
      abort "[ERROR] #{e.message}"
    end

  private

    def config
      @options[:config]
    end

    def commands
      [ 'start', 'redeploy' ]
    end

    def command_handler
      "handle_#{@command}"
    end

    def handle_start
      server = Kirk::Server.build(config)
      server.start
      server.join
    end

    def handle_redeploy
      rackup = File.expand_path(@options[:rackup] || "#{Dir.pwd}/config.ru")
      client = Server::RedeployClient.new('/tmp/kirk.sock')

      unless File.exist?(rackup)
        raise MissingRackupFile, "rackup file `#{rackup}` does not exist"
      end

      client.redeploy(rackup) do |log|
        puts log
      end
    end

    def default_options
      { :config => "#{Dir.pwd}/Kirkfile" }
    end

    def parser
      @parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: kirk [options] <command> [<args>]"

        opts.separator ""
        opts.separator "The available Kirk commands are:"
        opts.separator "   start      Start up Kirk"
        opts.separator "   redeploy   Redeploy a specific application"

        opts.separator ""
        opts.separator "Server options:"

        opts.on("-c", "--config FILE", "Load options from a config file") do |file|
          @options[:config] = file
        end

        opts.on("-R", "--rackup FILE", "Specify a rackup file") do |file|
          @options[:rackup] = file
        end

        opts.on("-h", "--help", "Show this message") do
          puts opts
          exit!
        end
      end
    end

    def parse!
      parser.parse! @argv
      @command = @argv.shift || "start"
    end
  end
end
