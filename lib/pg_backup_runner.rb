require "rest_client"
require "excon"
require "platform-api"
require "fog/aws"
require "json"
require "time"
require "tempfile"

class PgBackupRunner
  attr_reader :args

  def self.run(args)
    new(args).run
  end

  def initialize(args)
    @args = args
  end

  def run
    backups.select do |b|
      b["succeeded"] &&
      b["to_type"] == 'gof3r' &&
      (Time.now - 1_209_600) < Time.parse(b["created_at"]) && # 2 weeks
      s3_bucket.files.head(s3_file_key(b)).nil?
    end.each do |b|
      run_single(b)
    end
  end

  def run_single(backup = nil)
    backup ||= backup_for(args[:num].to_i) if !(args[:num].nil? || args[:num].blank?)
    backup ||= latest_backup
    archive(backup) && report_to_dms
  end

  def report_to_dms
    return unless dms_url

    require "net/http"
    Net::HTTP.get_response(URI(dms_url))
  end

  def backups
    @backups ||= JSON.parse(rest_client["transfers"].get).sort {|a,b| a["created_at"] <=> b["created_at"] }
  end

  def archive(backup)
    return false if s3_bucket.files.head(s3_file_key(backup))

    puts "Downloading #{app_name} #{backup["num"]}"

    temp_file = Tempfile.new("pgbackup")
    streamer = lambda do |chunk, remaining_bytes, total_bytes|
      print "\r%0.2f%%" % [100 - remaining_bytes.to_f / total_bytes * 100]
      temp_file.write chunk
    end

    # https://github.com/excon/excon/issues/475
    Excon.get public_url(backup["num"]),
      response_block: streamer,
      omit_default_port: true

    temp_file.rewind

    puts "\nUploading #{app_name} #{backup["num"]}"
    s3_bucket.files.create({
      key: s3_file_key(backup),
      body: temp_file,
      public: false,
      encryption: "AES256"
    })

    temp_file.delete

    true
  end

  protected

  # Connect to the Heroku Platform API
  # and retrieve the app config
  def app_env
    @_app_env ||= PlatformAPI.connect_oauth(heroku_api_key).config_var.info_for_app(app_name)
  end

  def app_name
    args[:app_name] || ENV["APP_NAME"]
  end

  def backup_for(num)
    backups.detect {|b| b["num"] == num } || raise("backup #{num} not found")
  end

  def dms_url
    app_env["PGBACKUPS_DMS_URL"]
  end

  def heroku_api_key
    args[:oauth_token] || ENV["OAUTH_TOKEN"]
  end

  def latest_backup
    backups.select { |b| b["succeeded"] && b["to_type"] == 'gof3r' }.sort_by { |b| b["created_at"] }.last
  end

  def public_url(num)
    JSON.parse(rest_client["transfers/#{num}/actions/public-url"].post("{}"))["url"]
  end

  def s3_bucket
    @_s3_bucket ||= s3_connection.directories.get app_env["PGBACKUPS_BUCKET"]
  end

  def s3_connection
    @_s3_connection ||= Fog::Storage.new({
      :provider              => "AWS",
      :aws_access_key_id     => app_env["PGBACKUPS_AWS_ACCESS_KEY_ID"],
      :aws_secret_access_key => app_env["PGBACKUPS_AWS_SECRET_ACCESS_KEY"],
      :region                => app_env["PGBACKUPS_REGION"],
      :persistent            => false
    })
  end

  def s3_file_key(backup)
    timestamp = backup["created_at"].gsub(/\/|\:|\.|\s/, "-").concat(".dump")
    ["pgbackups", app_env["RAILS_ENV"], timestamp].compact.join("/")
  end

  def rest_client
    RestClient::Resource.new(
      "https://postgres-api.heroku.com/client/v11/apps/#{app_name}",
      :user => "",
      :password => heroku_api_key
    )
  end
end
