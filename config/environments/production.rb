# -*- encoding : utf-8 -*-
Dengue::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  #----------------------------------------------------------------------------
  # Asset Compression and Compilation (JavaScripts and CSS)
  # NOTE: According to http://guides.rubyonrails.org/asset_pipeline.html,
  # sass-rails gem is used for CSS compression as long as we don't set css_compressor here.
  config.assets.compress       = true
  config.assets.js_compressor  = :uglifier

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  config.eager_load = true

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

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

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  config.assets.precompile += %w( jquery/* google/* googlemap/* bootstrap/* map.js map-2.js csv-ajax.js image-compression-verify.js image-compression.js moment.js datepicker.js)
  config.assets.precompile += %w( *.png *.jpg )
  config.assets.precompile += %w( app/* dashboard.css bootstrap/*.css jquery/*.css graphs.css )

  config.assets.paths << Rails.root.join("app", "assets", "templates")


  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # ActionMailer settings
  config.action_mailer.delivery_method     = :smtp
  config.action_mailer.default_url_options = { host: "www.denguetorpedo.com", protocol: "https" }

  # Gmail SMTP server setup
  config.action_mailer.smtp_settings = {
    :user_name => ENV['SENDGRID_USERNAME'],
    :password => ENV['SENDGRID_PASSWORD'],
    :domain => 'denguechat.org',
    :address => 'smtp.sendgrid.net',
    :port => 587,
    :authentication => :plain,
    :enable_starttls_auto => true
  }

  # Paperclip gem: ImageMagic path
  Paperclip.options[:command_path] = "/usr/local/bin/convert"

  # S3 Credential
  config.paperclip_defaults = {
    :storage => :s3,
    :s3_protocol => :https,
    :s3_credentials => {
      :bucket => ENV['S3_BUCKET_NAME'],
      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
    }
  }

end
