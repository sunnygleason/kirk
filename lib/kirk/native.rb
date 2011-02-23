require 'kirk/native.jar'

module Kirk
  Jetty # Trigger the jetty autoload

  module Native
    import "com.strobecorp.kirk.ApplicationConfig"
    import "com.strobecorp.kirk.HotDeployableApplication"
    import "com.strobecorp.kirk.LogFormatter"
    import "com.strobecorp.kirk.RewindableInputStream"
  end
end
