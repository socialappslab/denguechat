Dengue::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled.
  config.consider_all_requests_local       = false

  #----------------------------------------------------------------------------
  # Asset Compression and Compilation (JavaScripts and CSS)
  # NOTE: According to http://guides.rubyonrails.org/asset_pipeline.html,
  # sass-rails gem is used for CSS compression as long as we don't set css_compressor here.
  config.assets.compress       = true
  config.assets.js_compressor  = :uglifier

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Generate digests for assets URLs
  config.assets.digest                     = true
  config.static_cache_control              = "public, max-age=2592000"
  config.serve_static_assets               = true
  config.action_controller.perform_caching = true

  # Configure Rack::Cache to use Dalli Memcached client.
  client = Dalli::Client.new((ENV["MEMCACHIER_SERVERS"] || "").split(","),
                             :username => ENV["MEMCACHIER_USERNAME"],
                             :password => ENV["MEMCACHIER_PASSWORD"],
                             :failover => true,
                             :socket_timeout => 1.5,
                             :socket_failure_delay => 0.2,
                             :value_max_bytes => 10485760)
  config.action_dispatch.rack_cache = {
    :metastore    => client,
    :entitystore  => client
  }

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  config.assets.precompile += %w(jquery/* googlemap/* map.js bootstrap/* image-compression.js moment.js datepicker.js chart-options.js)

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true



  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Gmail SMTP
  config.action_mailer.delivery_method     = :smtp
  config.action_mailer.default_url_options = { host: "denguetorpedo-staging.herokuapp.com", protocol: "http" }

  config.action_mailer.delivery_method = :smtp
  # Gmail SMTP server setup
  config.action_mailer.smtp_settings = {
    :address => "smtp.gmail.com",
    :enable_starttls_auto => true,
    :port => 587,
    :domain => 'reportdengue@gmail.com',
    :authentication => :plain,
    :user_name => 'reportdengue',
    :password => 'dengue@!$'
  }

  # Paperclip gem: ImageMagic path
  Paperclip.options[:command_path] = "/usr/local/bin/convert"

  # S3 Credential
  config.paperclip_defaults = {
    :storage => :s3,
    :s3_credentials => {
      :bucket => ENV['S3_BUCKET_NAME'],
      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
    }
  }

end
