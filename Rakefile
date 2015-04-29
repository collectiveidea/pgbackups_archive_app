#!/usr/bin/env rake

require 'bundler/setup'

desc "Run backup for app"
task :backup, :app_name, :oauth_token do |t, args|
  require "pgbackups-archive"
  require "platform-api"

  ENV["HEROKU_API_KEY"] = args[:oauth_token] || ENV["OAUTH_TOKEN"]
  app_name = args[:app_name] || ENV["APP_NAME"]

  # Connect to the Heroku Platform API
  # and retrieve the app config
  heroku = PlatformAPI.connect_oauth(ENV["HEROKU_API_KEY"])
  env = heroku.config_var.info(app_name)

  # Configure the variables needed by pgbackups-archive
  ENV["DATABASE_URL"]                    = env["DATABASE_URL"]
  ENV["PGBACKUPS_APP"]                   = app_name
  ENV["PGBACKUPS_URL"]                   = env["PGBACKUPS_URL"]
  ENV["PGBACKUPS_AWS_ACCESS_KEY_ID"]     = env["PGBACKUPS_AWS_ACCESS_KEY_ID"]
  ENV["PGBACKUPS_AWS_SECRET_ACCESS_KEY"] = env["PGBACKUPS_AWS_SECRET_ACCESS_KEY"]
  ENV["PGBACKUPS_REGION"]                = env["PGBACKUPS_REGION"]
  ENV["PGBACKUPS_BUCKET"]                = env["PGBACKUPS_BUCKET"]

  # Run the archive command
  PgbackupsArchive::Job.call

  if env["PGBACKUPS_DMS_URL"]
    require "net/http"
    Net::HTTP.get_response(URI(env["PGBACKUPS_DMS_URL"]))
  end
end
