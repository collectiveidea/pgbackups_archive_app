#!/usr/bin/env rake

require 'bundler/setup'

desc "Run backup for app"
task :backup, :app_name, :oauth_token do |t, args|
  require File.expand_path("../lib/pg_backup_runner.rb", __FILE__)

  PgBackupRunner.run(args)
end
