package com.strobecorp.kirk;

import java.util.Map;
import org.eclipse.jetty.util.component.LifeCycle;

public interface ApplicationConfig {

  public String             getApplicationPath();
  public String             getRackupPath();
  public String             getBootstrapPath();
  public Map                getEnvironment();
  public LifeCycle.Listener getLifeCycleListener();

}
