require 'kirk/native.jar'

module Kirk
  Jetty # Trigger the jetty autoload

  module Native
    java_import "com.strobecorp.kirk.ApplicationConfig"
    java_import "com.strobecorp.kirk.ExtendedHttpRequestLogV20110917"
    java_import "com.strobecorp.kirk.HotDeployableApplication"
    java_import "com.strobecorp.kirk.LogFormatter"
    java_import "com.strobecorp.kirk.RewindableInputStream"
  end
end
