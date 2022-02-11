source 'http://rubygems.org'

# Analytics
gem "analytics-ruby", '~> 2.0.8', :require => 'segment/analytics'
gem 'angularjs-rails', "~> 1.4.8"

# File management and manipulation
# TODO: Update AWS to handle new versions
# See: http://stackoverflow.com/questions/28374401/nameerror-uninitialized-constant-paperclipstorages3aws
gem 'aws-sdk', '< 2.0'

gem 'bcrypt-ruby', '~> 3.1.2'

# TODO: Should we deprecate this? The only place where we use CanCan is when
# initializing a user.
gem 'cancan'
gem 'coffee-rails'
gem "connection_pool"

gem "devise-i18n"

gem "figaro"
gem "foreman"

gem 'haml', '5.1.2'
gem "http_accept_language"
gem 'responders', '~> 2.0'
gem "jbuilder"
gem 'jwt'
gem 'rubyXL'
gem 'paperclip', '~> 4.2.0'
gem "pg"
gem "pry"
# Needed for a smooth upgrade from Rails 3.2 to Rails 4.0
# http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html
gem 'protected_attributes'
gem "puma", "5.6.2"
gem "pundit"
gem "rack-cors", :require => false
gem 'rails', "4.2"
gem 'rails_autolink'
gem 'rails-i18n'
gem 'rollbar', '~> 2.2.1'
gem "roo", :require => false
gem 'sass-rails', "~> 5.0"
gem "sidekiq"
gem 'sinatra', :require => nil
gem 'uglifier', '>= 1.0.3'
gem "yuicompressor"

gem "tzinfo"
gem "byebug"

gem 'momentjs-rails'
gem 'bootstrap3-datetimepicker-rails'

gem 'jquery-rails'
gem 'activerecord-postgis-adapter', "~> 3.1.5"

gem 'google-analytics-rails', '1.1.1'

group :development do
  gem 'derailed_benchmarks', :git => "https://github.com/schneems/derailed_benchmarks.git", :require => false
  gem 'rack-mini-profiler', :require => false
  gem 'web-console', '~> 2.0'
end

#------------------------------------------------------------------------------

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'guard-rspec'
  gem 'launchy', :require => false
  gem "poltergeist"
  gem "spring", "~> 1.6.1"
  gem 'rspec-rails'
  gem "timecop", :require => false
end

#------------------------------------------------------------------------------

group :development, :test do
  gem 'spring-commands-rspec'
end


#------------------------------------------------------------------------------

group :production, :staging do
  gem "rails_12factor"
  gem "newrelic_rpm"
end

#------------------------------------------------------------------------------

group :development, :staging, :production do
  # Caching
  # See: https://devcenter.heroku.com/articles/rack-cache-memcached-rails31
  gem 'rack-cache'
  gem 'dalli'
  gem 'kgio'
  gem "memcachier"
end

#------------------------------------------------------------------------------
