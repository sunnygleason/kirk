require 'digest/sha1'

module Kirk
  module Applications
    # This class extends a native Java class
    class HotDeployable < Native::HotDeployableApplication

      def initialize(config)
        super(config)
        redeploy
      end

      def key
        gemfile  = "#{application_path}/Gemfile"
        lockfile = "#{application_path}/Gemfile.lock"

        if File.exist?(gemfile) && File.exist?(lockfile)
          str = File.read(gemfile) + File.read(lockfile)
          Digest::SHA1.hexdigest(str)
        end
      end

      def add_watcher(watcher)
        add_life_cycle_listener(watcher)
      end

      def application_path
        config.application_path
      end

      def last_modified
        mtimes = config.watch.map do |path|
          path = File.expand_path(path, application_path)
          File.exist?(path) ? File.mtime(path).to_i : 0
        end

        mtimes.max
      end

      def redeploy
        deploy(build_deploy)
      end

      def deploy(d)
        d.prepare
        super(d)
      end
    end
  end
end
