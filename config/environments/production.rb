# -*- encoding : utf-8 -*-
require "rack/cors"


Dengue::Application.configure do

  GA.tracker = 'UA-144181241-1'
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
  config.assets.compile = true
  config.serve_static_assets = true

  config.eager_load = true

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # See everything in the log (default is :info)
  config.log_level = :info

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Generate digests for assets URLs
  config.assets.digest                     = true
  config.static_cache_control              = "public, max-age=2592000"
  config.serve_static_files               = false
  config.action_controller.perform_caching = false

=begin
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
=end

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  config.assets.precompile += %w(google/marker-clusterer.js csv-ajax.js datepicker.js google-maps.js map-icons.min.js)
  config.assets.precompile += %w(bootstrap/typeahead.js bootstrap/bootstrap-multiselect.css bootstrap/marketing.css  map-icons.min.css)
  config.assets.precompile += %w(dashboard.css graphs.css select.css select-customizations.css)
  config.assets.precompile += %w( *.png *.jpg )
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

  #----------------------------------------------------------------------------
  # Mailer
  #-------
  config.action_mailer.delivery_method     = :smtp
  config.action_mailer.default_url_options = { host: "www.denguechat.com", protocol: "https" }
  config.action_mailer.smtp_settings = {
    :user_name => ENV['SENDGRID_USERNAME'],
    :password => ENV['SENDGRID_PASSWORD'],
    :domain => 'denguechat.org',
    :address => 'smtp.sendgrid.net',
    :port => 587,
    :authentication => :plain,
    :enable_starttls_auto => true
  }

  #----------------------------------------------------------------------------
  # Paperclip
  #----------
  Paperclip.options[:command_path] = "/usr/local/bin/convert"
  config.paperclip_defaults = {
    :storage => :s3,
    :s3_protocol => :https,
    :s3_credentials => {
      :bucket => ENV['S3_BUCKET_NAME'],
      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
    }
  }

  #----------------------------------------------------------------------------

  # See: https://github.com/cyu/rack-cors
  # NOTE: THis is only needed in development.rb because production Ionic is
  # using file:// and not http://
  # See http://blog.ionic.io/handling-cors-issues-in-ionic/
  # NOTE: We're including this in production in an attempt to solve Huawei Android 5
  # issues with "Request denied for security" error message. See
  # https://github.com/socialappslab/denguechat-ionic/issues/79
  config.middleware.insert_before 0, "Rack::Cors" do
    allow do
      # origins 'localhost:8100', "192.168.86.196"
      origins "*"
      resource '*', :headers => :any, :methods => [:get, :put, :post, :options, :delete]
    end
  end
end
