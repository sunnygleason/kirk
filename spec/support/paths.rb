module SpecHelpers
  include FileUtils

  def reset!
    rm_rf   tmp
    mkdir_p tmp
    cp_r    spec('support/applications'), tmp
  end

  def root
    @root ||= Pathname.new(File.expand_path("../../..", __FILE__))
  end

  def spec(*args)
    root.join('spec', *args)
  end

  def application_path(*args)
    tmp('applications', *args)
  end

  def hello_world_path(*args)
    application_path('hello_world', *args)
  end

  def goodbye_world_path(*args)
    application_path('goodbye_world', *args)
  end

  def randomized_app_path(*args)
    application_path('randomized', *args)
  end

  def echo_app_path(*args)
    application_path('echo_app', *args)
  end

  def require_as_app_path(*args)
    application_path('require_as', *args)
  end

  def bundled_app_path(*args)
    application_path('bundled_app', *args)
  end

  def blacksheep_path(*args)
    application_path('blacksheep', *args)
  end

  def kirked_up_path(*args)
    application_path('kirked_up', *args)
  end

  def umask_path(*args)
    application_path('umask', *args)
  end

  def reveal_env_path(*args)
    application_path('reveal_env', *args)
  end

  def tmp(*args)
    root.join('tmp', *args)
  end
end
