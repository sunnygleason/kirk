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

      # For our ROFL scale needs
      import "java.util.concurrent.LinkedBlockingQueue"

      BUFFER_POOL    = LinkedBlockingQueue.new
      TMPFILE_PREFIX = "rackinput".to_java_string
      TMPFILE_SUFFIX = "".to_java_string

      def initialize(io)
        @io       = channelize(io)
        @buffer   = grab_buffer
        @filebuf  = nil
        @read     = 0
        @position = 0
        @eof      = false
      end

      def read(size = nil, buffer = nil)
        one_loop = nil
        read_all = size.nil?

        buffer ? buffer.slice!(0..-1) : buffer = ''

        raise ArgumentError, "negative length #{size} given" if size && size < 0

        loop do
          limit = size && size < CHUNK_SIZE ? size : CHUNK_SIZE

          len = read_chunk(limit, buffer)

          break unless len

          one_loop = true

          break if size && ( size -= len ) <= 0
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
        @position
      end

      def seek(pos)
        raise Errno::EINVAL, "Invalid argument - invalid seek value" if pos < 0
        @position = pos
      end

      def rewind
        seek(0)
      end

      def close
        nil
      end

      def recycle
        BUFFER_POOL.put(@buffer)
        @buffer = nil
        nil
      end

    private

      def channelize(stream)
        Channels.new_channel(stream)
      end

      def grab_buffer
        BUFFER_POOL.poll || ByteBuffer.allocate(BUFFER_SIZE)
      end

      def read_chunk(size, string)
        missing = size - ( @read - @position )

        if @filebuf || @read + missing > BUFFER_SIZE

          rotate_to_tmp_file unless @filebuf
          read_chunk_from_tmp_file(size, string)

        else

          read_chunk_from_mem(missing, string)

        end
      end

      def read_chunk_from_mem(missing, string)
        # We gonna have to read from the input stream
        if missing > 0 && !@eof

          # Set the new buffer limit to the amount that is going
          # to be read
          @buffer.position(@read).limit(@read + missing)

          # Read into the buffer
          len = @io.read(@buffer)

          # Bail if we're at the EOF
          if len == -1
            @eof = true
            return
          end

          @read += len

        # We're at the end
        elsif @position == @read

          return

        end

        # Now move the amount read into the string
        @buffer.position(@position).limit(@read)

        append_buffer_to_string(@buffer, string)
      end

      def read_chunk_from_tmp_file(size, string)

        if @read < @position && !@eof

          return unless buffer_to(@position)

        end

        @buffer.clear.limit(size)

        if @read > @position

          @filebuf.position(@position)
          @filebuf.read(@buffer)

        elsif @eof

          return

        end

        unless @eof

          offset = @buffer.position
          len    = @io.read(@buffer)

          if len == -1

            @eof = true
            return if offset == 0

          else

            @filebuf.position(@read)
            @filebuf.write(@buffer.flip.position(offset))

            @read += len

          end

          @buffer.position(0)

        end

        append_buffer_to_string(@buffer, string)
      end

      def buffer_to(position)
        until @read == position
          limit = position - @read
          limit = BUFFER_SIZE if limit > BUFFER_SIZE

          @buffer.clear.limit(limit)

          len = @io.read(@buffer)

          if len == -1
            @eof = true
            return
          end

          @buffer.flip

          @filebuf.position(@read)
          @filebuf.write(@buffer)

          @read += len
        end

        true
      end

      def append_buffer_to_string(buffer, string)
        len   = buffer.limit - buffer.position
        bytes = Java::byte[len].new
        buffer.get(bytes)
        string << String.from_java_bytes(bytes)
        @position += len
        len
      end

      def rotate_to_tmp_file
        @buffer.position(0).limit(@read)

        @filebuf = create_tmp_file
        @filebuf.write @buffer

        @buffer.clear
      end

      def create_tmp_file
        file = File.create_temp_file(TMPFILE_PREFIX, TMPFILE_SUFFIX)
        file.delete_on_exit

        RandomAccessFile.new(file, "rw").channel
      end
    end
  end
end
