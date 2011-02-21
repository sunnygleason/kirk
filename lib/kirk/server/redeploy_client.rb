require 'socket'

module Kirk
  class Server::RedeployClient
    def self.redeploy(socket, path, &blk)
      new(socket).redeploy(path, &blk)
    end

    def initialize(unix_socket_path)
      @unix_socket, @unix_socket_path = nil, unix_socket_path
    end

    def redeploy(path, &blk)
      connect
      @unix_socket.write "REDEPLOY #{path}\n"
      handle_response(&blk)
    ensure
      disconnect
    end

  private

    def connect
      @unix_socket = UNIXSocket.new(@unix_socket_path)
    end

    def disconnect
      @unix_socket.close
    end

    def handle_response(&blk)
      yield "Waiting for response..." if block_given?

      while line = @unix_socket.gets
        msg = case line
        when /^INFO (.*)$/  then $1
        when /^ERROR (.*)$/ then "[ERROR] #{$1}"
        else "[ERROR] Received unknown message: `#{line}`"
        end

        yield msg if block_given?
      end
    end
  end
end
