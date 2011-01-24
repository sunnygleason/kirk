module Kirk
  # This class extends a native Java class
  class Application
    # Be able to listen to when the application is
    # starting so that the watcher thread can be
    # spawned
    class WatcherThread
      include Jetty::LifeCycle::Listener

      def initialize
        @thread, @last_modified = nil, nil
      end

      def life_cycle_failure(app, cause)
        # nothing
      end

      def life_cycle_started(app)
        spawn_watcher_thread(app)
      end

      def life_cycle_starting(app)
        # nothing
      end

      def life_cycle_stopped(app)
        # nothing
      end

      def life_cycle_stopping(app)
        # nothing
      end

    private

      def spawn_watcher_thread(app)
        @thread = Thread.new do
          @last_modified = app.last_modified

          loop do
            sleep 0.1
            last_modified = app.last_modified

            if last_modified > @last_modified
              app.reload_deploy
              @last_modified = last_modified
            end
          end
        end
      end
    end

    def application_path
      config.application_path
    end

    def last_modified
      path = "#{application_path}/REVISION"

      return 0 unless File.exist?(path)

      File.mtime(path).to_i
    end
  end
end