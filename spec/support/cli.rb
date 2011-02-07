module SpecHelpers
  attr_reader :last_command

  class Command
    attr_reader :stdout, :stderr, :stdin, :pid, :exit_status

    def initialize(cmd)
      @cmd         = cmd
      @stdout      = nil
      @stderr      = nil
      @stdin       = nil
      @pid         = nil
      @exit_status = nil
    end

    def run
      IO.popen4(@cmd) do |pid, stdin, stdout, stderr|
        @pid    = pid
        @stdin  = stdin
        @stdout = stdout
        @stderr = stderr

        begin
          yield self if block_given?
        ensure
          Process.kill("HUP", @pid) rescue nil
        end
      end

      @exit_status = $?.exitstatus
    end
  end

  def kirk(cmd = "", &blk)
    command = Command.new("kirk #{cmd}")
    command.run(&blk)

    @last_command = command
  end
end
