# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

at_exit do
  # Cleanup after the JDBC drives
  ActiveRecord::Base.clear_all_connections!
end

run TrainApp::Application
