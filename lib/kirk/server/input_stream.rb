module Kirk
  class Server
    class InputStream
      READL_SIZE  = 1_024
      CHUNK_SIZE  = 8_192
      BUFFER_SIZE = 1_024 * 50

      import "java.io.File"
      import "java.io.RandomAccessFile"
      import "java.nio.ByteBuffer"
      import "java.nio.channels.Channels"

      BUFFER_POOL = LinkedBlockingQueue.new

      def initialize(io)
        @io, @buffer = init_rewindable_input(io)
      end

      def read(size = nil, buffer = nil)
        one_loop = nil
        read_all = size.nil?

        buffer ? buffer.slice!(0..-1) : buffer = ''

        raise ArgumentError, "negative length #{size} given" if size && size < 0

        loop do
          limit = size && size < CHUNK_SIZE ? size : CHUNK_SIZE
          data  = @io.read(limit)

          break unless data

          one_loop = true

          buffer << String.from_java_bytes(data)

          break if size && ( size -= data.length ) <= 0
        end

        return "" if read_all && !one_loop

        one_loop && buffer
      end

      def gets(sep = $/)
        return read unless sep

        sep    = "#{$/}#{$/}" if sep == ""
        buffer = ''
        curpos = pos

        while chunk = read(READL_SIZE)
          buffer << chunk

          if i = buffer.index(sep, 0)
            i += sep.bytesize
            buffer.slice!(i..-1)
            seek(curpos + buffer.bytesize)
            break
          end
        end

        buffer
      end

      def each
        while chunk = read(CHUNK_SIZE)
          yield chunk
        end

        self
      end

      def pos
        @io.position
      end

      def seek(pos)
        raise Errno::EINVAL, "Invalid argument - invalid seek value" if pos < 0
        @io.seek(pos)
      end

      def rewind
        @io.rewind
      end

      def close
        p [ :CLOSE ]
        @io.close
      end

      def recycle
        p [ :RECYCLE ]
        @io.close

        BUFFER_POOL.put(@byte_buffer)

        @buffer, @io = nil, nil
      end

    private

      def grab_buffer
        BUFFER_POOL.poll || ByteBuffer.allocate(BUFFER_SIZE)
      end

      def init_rewindable_input(io)
        buf = grab_buffer
        [ Native::RewindableInputStream.new(io, buf), buf ]
      end
    end
  end
end
