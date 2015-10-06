# -*- encoding : utf-8 -*-
$stdout.sync = true
Dengue::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false
  config.consider_all_requests_local       = true


  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  config.eager_load = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # http://stackoverflow.com/questions/8031007/how-to-increase-heroku-log-drain-verbosity-to-include-all-rails-app-details/8075630#8075630
  STDOUT.sync = true
  logger = Logger.new(STDOUT)
  logger.level = 0
  Rails.logger = Rails.application.config.logger = logger


  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false
  # config.assets.js_compressor  = :uglifier

  # Expands the lines which load the assets
  config.assets.debug = false
  config.log_level = :debug


  # config.assets.digest                     = true
  # config.static_cache_control              = "public, max-age=2592000"
  # config.serve_static_files               = true
  config.action_controller.perform_caching = false

  #----------------------------------------------------------------------------
  # Mailer
  #-------
  config.action_mailer.default_url_options   = { :host => 'localhost:5000' }
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method       = :file

  #----------------------------------------------------------------------------
  # Paperclip
  #----------
  Paperclip.options[:command_path] = "/usr/local/bin/convert"
  config.paperclip_defaults = {
    :storage => :filesystem
  }

  #----------------------------------------------------------------------------
end
