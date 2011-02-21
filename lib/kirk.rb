module Kirk
  # Make sure that the version of JRuby is new enough
  unless (JRUBY_VERSION.split('.')[0..2].map(&:to_i) <=> [1, 6, 0]) >= 0
    raise "Kirk requires JRuby 1.6.0 RC 1 or greater. This is due to "   \
          "a bug that was fixed in the 1.6 line but not backported to "  \
          "older versions of JRuby. If you want to use Kirk with older " \
          "versions of JRuby, bug headius."
  end

  require 'java'
  require 'kirk/common'
  require 'kirk/version'
  require 'kirk/native'
  require 'kirk/jetty'

  import "java.util.concurrent.LinkedBlockingQueue"
  import "java.util.concurrent.TimeUnit"
  import "java.util.logging.Logger"
  import "java.util.logging.Level"
  import "java.util.logging.ConsoleHandler"

  module Native
    import "com.strobecorp.kirk.ApplicationConfig"
    import "com.strobecorp.kirk.HotDeployableApplication"
    import "com.strobecorp.kirk.LogFormatter"
  end

  require 'kirk/server/builder'
  require 'kirk/client'
  require 'kirk/server/handler'
  require 'kirk/server/input_stream'
  require 'kirk/server'

  # Configure the logger
  def self.logger
    @logger ||= begin
      logger = Logger.get_logger("org.eclipse.jetty.util.log")
      logger.set_use_parent_handlers(false)
      logger.add_handler logger_handler
      logger
    end
  end

  def self.logger_handler
    ConsoleHandler.new.tap do |handler|
      handler.set_output_stream(java::lang::System.out)
      handler.set_formatter(Native::LogFormatter.new)
    end
  end
end
