require "pgbackups-archive"
require "platform-api"

class PgBackupRunner
  attr_reader :args

  def self.run(args)
    new(args).run
  end

  def initialize(args)
    @args = args
  end

  def run
    setup
    backup
    report_to_dms
  end

  def setup
    ENV["HEROKU_API_KEY"] = args[:oauth_token] || ENV["OAUTH_TOKEN"]

    # Configure the variables needed by pgbackups-archive
    ENV["DATABASE_URL"]                    = app_env["DATABASE_URL"]
    ENV["PGBACKUPS_APP"]                   = app_name
    ENV["PGBACKUPS_URL"]                   = app_env["PGBACKUPS_URL"]
    ENV["PGBACKUPS_AWS_ACCESS_KEY_ID"]     = app_env["PGBACKUPS_AWS_ACCESS_KEY_ID"]
    ENV["PGBACKUPS_AWS_SECRET_ACCESS_KEY"] = app_env["PGBACKUPS_AWS_SECRET_ACCESS_KEY"]
    ENV["PGBACKUPS_REGION"]                = app_env["PGBACKUPS_REGION"]
    ENV["PGBACKUPS_BUCKET"]                = app_env["PGBACKUPS_BUCKET"]
  end

  # Run the archive command
  def backup
    PgbackupsArchive::Job.call
  end

  def report_to_dms
    return unless dms_url

    require "net/http"
    Net::HTTP.get_response(URI(dms_url))
  end

  protected

  # Connect to the Heroku Platform API
  # and retrieve the app config
  def app_env
    @app_env ||= PlatformAPI.connect_oauth(ENV["HEROKU_API_KEY"]).config_var.info(app_name)
  end

  def app_name
    args[:app_name] || ENV["APP_NAME"]
  end

  def dms_url
    app_env["PGBACKUPS_DMS_URL"]
  end
end
