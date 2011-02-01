# Kirk: a JRuby Rack server based on Jetty

Kirk is a wrapper around Jetty that hides all of the insanity and wraps your
Rack application in a loving embrace. Also, Kirk is probably the least HTTP
retarded ruby rack server out there.

### TL;DR

    gem install kirk
    rackup -s Kirk config.ru

### Features

Here is a brief highlight of some of the features available.

* 0 Downtime deploys: Deploy new versions of your rack application without
  losing a single request. The basic strategy is similar to Passenger.
  Touch a magic file in the application root and Kirk will reload the
  application without dropping a single request... It's just magic.

* Request body streaming: Have a large request body to handle? Why wait until
  receiving the entire thing before starting the work?

* HTTP goodness: `Transfer-Encoding: chunked`, `Content-Encoding: gzip` (and
  deflate) support on the request.

* Concurrency: As it turns out, it's nice to not block your entire application
  while waiting for an HTTP request to finish. It's also nice to be able to
  handle more than 50 concurrent requests without burning over 5GB of RAM. Sure,
  RAM is cheap, but using Kirk is cheaper ;)

* Run on the JVM: I, for one, am a fan of having a predictable GC, a JIT
  compiler, and other goodness.

### Getting Started

To take advantage of the zero downtime redeploy features, you will need to
create a configuration file that describes to Kirk how to start and watch the
rack application. You can create the file anywhere. For example, let's say that
we are going to put the following configuration file at `/path/to/Kirkfile`.

    # Set the log level to ALL.
    log :level => :all

    rack "/path/to/my/rackup/config.ru" do
      # Set the host and / or port that this rack application will
      # be available on. This defaults to "0.0.0.0:9090"
      listen 80

      # Set the host names that this rack application wll be available
      # on. This defaults to "*"
      hosts "example.com", "*.example.org"

      # Set the file that controls the redeploys. This is relative to
      # the applications root (the directory that the rackup file lives
      # in). Touch this file to redepoy the application.
      watch "REVISION"
    end

    rack "/path/to/another/rackup/config.ru" do
      # More settings here
    end

Once you have Kirk configured, start it up with the following command:

    kirk -c /path/to/Kirkfile

... and you're off.

### Daemonizing Kirk

Use your OS features. For example, write an upstart script or use
`start-stop-daemon`.

### Logging to a file or syslog

Kirk just dumps logs to stdout, so just pipe Kirk to `logger`.

### Caveats

This is still a pretty new project and a lot of settings that should be
abstracted are still hardcoded in the source.

* Kirk requires JRuby 1.6.0 RC 1 or greater. This is due to a JRuby bug that
  was fixed in the 1.6 branch but never backported to older versions of JRuby.
  Crazy stuff happens without the bug fix.

* The JDBC drivers will keep connections open unless they are explicitly
  cleaned up, something which Rack applications do not do. A future release of
  the jdbc ruby drivers will correctly clean up after the JDBC garbage, but for
  now, you will have to manually do it. If you are running a Rails app, add the
  following to the config.ru file:

    at_exit { ActiveRecord::Base.clear_all_connections! }

### Getting Help

Ping me (carllerche) on Freenode in #carlhuda

### Reporting Bugs

Just post them to the Github repository's issue tracker.
