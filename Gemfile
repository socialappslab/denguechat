source 'http://rubygems.org'

ruby "1.9.3"
gem 'rails', '~> 3.2.1'

group :staging, :production do
  gem 'pg'
end

#------------------------------------------------------------------------------
# Encoding support

gem 'magic_encoding'
gem 'mime' # TODO: Possibly deprecate?

#------------------------------------------------------------------------------
# Maps

gem 'geokit'
gem 'leaflet-rails'

#------------------------------------------------------------------------------
# SMS communication

gem 'nexmo'
gem 'mms2r'

#------------------------------------------------------------------------------
# User management

gem 'bcrypt-ruby', '~> 3.0.0'
gem 'cancan'

#------------------------------------------------------------------------------
# Email communication

gem 'ruby-gmail'

#------------------------------------------------------------------------------
# PDF-related

gem 'prawn'
gem 'prawn-layout'
gem "prawnto_2", :require => "prawnto"

#------------------------------------------------------------------------------
# Internationalization

gem 'rails-i18n'
gem "countries"
gem "devise-i18n"

#------------------------------------------------------------------------------
# Front-end tools

gem 'haml'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'dynamic_form'
gem 'rails_autolink'

#------------------------------------------------------------------------------
# Assets

gem 'yui-compressor'
group :assets do
  gem 'sass-rails', "~> 3.2.3"
  gem 'bootstrap-sass', '~> 2.0.3'
  gem 'coffee-rails', "~> 3.2.1"
  gem 'uglifier', '>= 1.0.3'
end

#------------------------------------------------------------------------------
# Image Management and Processing

gem 'aws-sdk'
gem 'rmagick'
gem 'paperclip', :git => 'git://github.com/thoughtbot/paperclip'

#------------------------------------------------------------------------------
# Server Management

gem "puma"
gem "foreman"
gem "therubyracer"

#------------------------------------------------------------------------------
# Workers

gem "sidekiq"
gem 'sinatra', '>= 1.3.0', :require => nil

#------------------------------------------------------------------------------
# Testing

group :test, :development do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'capybara'         # lets Cucumber pretend to be a web browser
  gem 'launchy'          # a useful debugging aid for user stories
  gem 'sqlite3'
end

group :test do
  gem 'guard-rspec'
  gem 'database_cleaner'
  gem 'faker'
end

#------------------------------------------------------------------------------
# Administration

gem "activeadmin"

#------------------------------------------------------------------------------
# TODO

# TODO: Deprecate after refactoring Post model.
gem 'awesome_nested_set'

# TODO: Deprecate after refactoring Feed model.
gem 'simple_enum'

#------------------------------------------------------------------------------
# Heroku-specific gems

group :production, :staging do
  gem "rails_12factor"
end

#------------------------------------------------------------------------------
