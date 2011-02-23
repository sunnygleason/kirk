# Only require jars if in the "master" process
unless Kirk.sub_process?
  require "kirk/jetty/servlet-api-2.5"

  %w(util http io continuation server client).each do |mod|
    require "kirk/jetty/jetty-#{mod}-7.3.0.v20110203"
  end
end

module Kirk
  module Jetty
    # Gimme Jetty
    import "org.eclipse.jetty.client.HttpClient"
    import "org.eclipse.jetty.client.HttpExchange"
    import "org.eclipse.jetty.client.ContentExchange"

    import "org.eclipse.jetty.io.ByteArrayBuffer"

    import "org.eclipse.jetty.server.nio.SelectChannelConnector"
    import "org.eclipse.jetty.server.handler.AbstractHandler"
    import "org.eclipse.jetty.server.handler.ContextHandler"
    import "org.eclipse.jetty.server.handler.ContextHandlerCollection"
    import "org.eclipse.jetty.server.Server"

    import "org.eclipse.jetty.util.component.LifeCycle"
    import "org.eclipse.jetty.util.log.Log"
    import "org.eclipse.jetty.util.log.JavaUtilLog"

    Log.set_log Jetty::JavaUtilLog.new unless Kirk.sub_process?
  end
end
