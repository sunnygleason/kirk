# Only require jars if in the "master" process
unless Kirk.sub_process?
  require "kirk/jetty/jetty-client-7.2.2.v20101205"
  require "kirk/jetty/jetty-server-7.2.2.v20101205"
  require "kirk/jetty/servlet-api-2.5"
end

module Kirk
  module Jetty
    # Gimme Jetty
    import "org.eclipse.jetty.client.HttpClient"
    import "org.eclipse.jetty.client.HttpExchange"
    import "org.eclipse.jetty.client.ContentExchange"

    import "org.eclipse.jetty.server.nio.SelectChannelConnector"
    import "org.eclipse.jetty.server.handler.AbstractHandler"
    import "org.eclipse.jetty.server.handler.ContextHandler"
    import "org.eclipse.jetty.server.handler.ContextHandlerCollection"
    import "org.eclipse.jetty.server.Server"

    import "org.eclipse.jetty.util.component.LifeCycle"
    import "org.eclipse.jetty.util.log.Log"
    import "org.eclipse.jetty.util.log.JavaUtilLog"

    Log.set_log Jetty::JavaUtilLog.new
  end
end
