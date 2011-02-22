package com.strobecorp.kirk;

import java.io.File;
import java.io.FilterInputStream;
import java.io.InputStream;
import java.io.IOException;
import java.io.RandomAccessFile;

import java.nio.ByteBuffer;
import java.nio.channels.Channels;
import java.nio.channels.FileChannel;
import java.nio.channels.ReadableByteChannel;

public class RewindableInputStream extends FilterInputStream {
  // The default buffer size
  public static final int DEFAULT_BUFFER_SIZE = 8192;

  // The tmp files prefix
  public static final String TMPFILE_PREFIX = "kirk-rewindable-input";

  // The tmp file's suffix
  public static final String TMPFILE_SUFFIX = "";

  // The in memory buffer, the wrapped stream will be buffered
  // in memory until this buffer is full, then it will be written
  // to a temp file.
  private ByteBuffer buf;

  // The wrapped stream converted to a Channel
  private ReadableByteChannel io;

  // The total number of bytes buffered
  private long buffered;

  // The current position within the stream
  private long position;

  // The last remembered position
  private long mark;

  // The on disk stream buffer
  private FileChannel tmpFile;

  public RewindableInputStream(InputStream io) {
    this(io, DEFAULT_BUFFER_SIZE);
  }

  public RewindableInputStream(InputStream io, int bufSize) {
    this(io, ByteBuffer.allocate(bufSize));
  }

  public RewindableInputStream(InputStream io, ByteBuffer buf) {
    super(io);

    this.buffered = 0;
    this.position = 0;
    this.mark     = -1;

    this.io  = Channels.newChannel(io);
    this.buf = buf;
  }

  public InputStream getUnbufferedInputStream() {
    return in;
  }

  @Override
  public synchronized int available() throws IOException {
    long available = buffered - position;

    if ( available > Integer.MAX_VALUE ) {
      available = Integer.MAX_VALUE;
    }
    else if ( available < 0 ) {
      throw new IOException("Somehow the stream travelled to the future :(");
    }

    return (int) available;
  }

  @Override
  public void close() throws IOException {
  }

  @Override
  public synchronized void mark(int readlimit) {
    this.mark = this.position;
  }

  @Override
  public boolean markSupported() {
    return true;
  }

  @Override
  public synchronized int read() throws IOException {
    long len;

    while ( true ) {
      len = fillBuf(1);

      if ( len == -1 ) {
        return -1;
      }
      else if ( len == 1 ) {
        return buf.get();
      }

      throw new IOException("WTF mate");
    }
  }

  @Override
  public synchronized int read(byte[] buffer, int offset, int length) throws IOException {
    int count = 0;
    int len;

    while ( count < length ) {
      // Fill the buffer
      len = (int) fillBuf(length - count);

      // Handle EOFs
      if ( len == -1 ) {
        if ( count == 0 ) {
          count = -1;
        }

        break;
      }

      buf.get(buffer, offset + count, len);
      position += len;
      count    += len;
    }

    return count;
  }

  @Override
  public synchronized void reset() throws IOException {
    if ( mark < 0 ) {
      throw new IOException("The marked position is invalid");
    }

    position = mark;
  }

  @Override
  public synchronized long skip(long amount) throws IOException {
    long count = 0;
    long len;

    while ( amount > count ) {
      len = fillBuf(amount - count);

      if ( len == -1 ) {
        break;
      }

      count += len;
    }

    return count;
  }

  public synchronized void seek(long newPosition) {
    this.position = newPosition;
  }

  public synchronized void rewind() {
    seek(0);
  }

  private long fillBuf(long length) throws IOException {
    if ( isOnDisk() || position + length > buf.capacity() ) {
      // Rotate the buffer to disk if it hasn't been done yet
      if ( !isOnDisk() ) {
        rotateToTmpFile();
      }

      fillBufFromTmpFile(length);
    }
    else {
      return fillBufFromMem(length);
    }

    return 0;
  }

  private long fillBufFromMem(long length) throws IOException {
    long limit;
    int  len;

    limit = position + length;
    buf.limit((int) limit).position((int) buffered);

    len = io.read(buf);

    if ( len == -1 ) {
      return -1;
    }

    buf.flip();

    buffered += len;

    return Math.max(0, buffered - position);
  }

  private long fillBufFromTmpFile(long length) throws IOException {
    long count = 0;
    int  len;

    // If we haven't buffered far enough, then do it
    if ( buffered < position ) {
      // Bail with an EOF if there isn't enough data to buffer
      // to the requested position.
      if ( !bufferTo(position) ) {
        return -1;
      }
    }

    buf.clear().limit((int) length);

    if ( buffered > position ) {
      tmpFile.position(position);
      len = tmpFile.read(buf);
      buf.flip();

      return len;
    }
    else {
      // Read from the network
      len = io.read(buf);

      if ( len == -1 ) {
        return -1;
      }

      buf.flip().mark();

      tmpFile.position(buffered);
      tmpFile.write(buf);
      buf.reset();

      return len;
    }
  }

  private boolean bufferTo(long pos) throws IOException {
    long limit;
    int  len;

    while ( buffered < pos ) {
      limit = pos - buffered;

      buf.clear().limit((int) limit);

      len = io.read(buf);

      if ( len == -1 ) {
        return false;
      }

      buf.flip();

      tmpFile.position(buffered);
      tmpFile.write(buf);

      buffered += len;
    }

    return true;
  }

  private boolean isInMemory() {
    return tmpFile == null;
  }

  private boolean isOnDisk() {
    return tmpFile != null;
  }

  private void rotateToTmpFile() throws IOException {
    File file;
    RandomAccessFile fileStream;

    file = File.createTempFile(TMPFILE_PREFIX, TMPFILE_SUFFIX);
    file.deleteOnExit();

    fileStream = new RandomAccessFile(file, "rw");
    tmpFile    = fileStream.getChannel();

    buf.position(0).limit((int) buffered);
    tmpFile.write(buf);
    buf.clear();
  }
}
