#!/usr/bin/env rake

require 'bundler/setup'

desc "Run backup for app"
task :run_backup do
  require "pgbackups-archive"
  require "platform-api"

  # Connect to the Heroku Platform API
  # and retrieve the app config
  heroku = PlatformAPI.connect_oauth(ENV["OAUTH_TOKEN"])
  env = heroku.config_var.info(ENV["APP_NAME"])

  # Configure the variables needed by pgbackups-archive
  ENV["PGBACKUPS_DATABASE_URL"]          = env["DATABASE_URL"]
  ENV["PGBACKUPS_URL"]                   = env["PGBACKUPS_URL"]
  ENV["PGBACKUPS_AWS_ACCESS_KEY_ID"]     = env["PGBACKUPS_AWS_ACCESS_KEY_ID"]
  ENV["PGBACKUPS_AWS_SECRET_ACCESS_KEY"] = env["PGBACKUPS_AWS_SECRET_ACCESS_KEY"]
  ENV["PGBACKUPS_REGION"]                = env["PGBACKUPS_REGION"]
  ENV["PGBACKUPS_BUCKET"]                = env["PGBACKUPS_BUCKET"]

  # Run the archive command
  Heroku::Client::PgbackupsArchive.perform
end
