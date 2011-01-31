package com.strobecorp.kirk;

import java.io.IOException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.ServletException;
import org.eclipse.jetty.server.Request;
import org.jruby.embed.PathType;
import org.jruby.embed.LocalContextScope;
import org.jruby.embed.ScriptingContainer;
import org.jruby.runtime.builtin.IRubyObject;

public class Deploy {

  private ApplicationConfig  config;
  private ScriptingContainer context;
  private Object             bootstrapper;
  private Object             handler;
  private String             key;

  public Deploy(ApplicationConfig config) {
    this.config = config;
    initializeScriptingContext();
  }

  public void prepare() {
    this.handler = context.callMethod(bootstrapper, "run",
      config.getRackupPath());
  }

  public void handle(String target, Request baseRequest,
      HttpServletRequest request, HttpServletResponse response)
      throws IOException, ServletException {
    context.callMethod(handler, "handle", target, baseRequest, request, response);
  }

  public String getKey() {
    return key;
  }

  public void terminate() {
    this.context.terminate();
    this.context = null;
    this.handler = null;
  }

  private void initializeScriptingContext() {
    this.context = new ScriptingContainer(LocalContextScope.SINGLETHREAD);
    this.bootstrapper = context.runScriptlet(
      PathType.ABSOLUTE, config.getBootstrapPath());

    key = (String) context.callMethod(bootstrapper, "warmup",
      config.getApplicationPath());
  }

}
