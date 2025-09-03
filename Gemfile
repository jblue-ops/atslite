source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2", ">= 8.0.2.1"

# The original asset pipeline for Rails [https://github.com/rails/sprockets]
gem "sprockets-rails"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.6"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Authentication solution for Rails [https://github.com/heartcombo/devise]
gem "devise"

# Authorization gem for Ruby on Rails [https://github.com/varvet/pundit]
gem "pundit"

# PostgreSQL full-text search [https://github.com/Casecommons/pg_search]
gem "pg_search"

# State machine for ActiveRecord [https://github.com/state-machines/state_machines-activerecord]
gem "state_machines-activerecord"

# Tagging plugin for Rails applications [https://github.com/mbleigh/acts-as-taggable-on]
gem "acts-as-taggable-on"

# Background job processing [https://github.com/sidekiq/sidekiq]
gem "sidekiq"

# Multi-tenancy for Rails applications [https://github.com/excid3/acts_as_tenant]
gem "acts_as_tenant"

# Activity tracking for your ActiveRecord models [https://github.com/chaps-io/public_activity]
gem "public_activity"

# Image processing for ActiveStorage [https://github.com/janko/image_processing]
gem "image_processing", "~> 1.2"

# Rich text editor [https://guides.rubyonrails.org/action_text_overview.html]
gem "actiontext"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # RSpec testing framework for Rails [https://github.com/rspec/rspec-rails]
  gem "rspec-rails"

  # Factory Bot for fixtures replacement [https://github.com/thoughtbot/factory_bot_rails]
  gem "factory_bot_rails"

  # Generate fake data for testing [https://github.com/faker-ruby/faker]
  gem "faker"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Ruby code style checker [https://github.com/rubocop/rubocop-rails]
  gem "rubocop-rails", require: false
  
  # Performance-focused RuboCop rules [https://github.com/rubocop/rubocop-performance]
  gem "rubocop-performance", require: false
  
  # RSpec-focused RuboCop rules [https://github.com/rubocop/rubocop-rspec]
  gem "rubocop-rspec", require: false
  
  
  # Dependency vulnerability scanner [https://github.com/rubysec/bundler-audit]
  gem "bundler-audit", require: false
  
  # Test coverage analysis [https://github.com/simplecov-ruby/simplecov]
  gem "simplecov", require: false
  
  # SimpleCov formatter for HTML reports [https://github.com/simplecov-ruby/simplecov-html]
  gem "simplecov-html", require: false
  
  # SimpleCov formatter for console output [https://github.com/simplecov-ruby/simplecov-console]
  gem "simplecov-console", require: false
  
  # RSpec JUnit formatter for CI integration [https://github.com/sj26/rspec_junit_formatter]
  gem "rspec_junit_formatter", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Preview email in the browser instead of sending [https://github.com/ryanb/letter_opener]
  gem "letter_opener"

  # Spring speeds up development by keeping your application running in the background
  gem "spring"
  gem "spring-commands-rspec"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"

  # Database cleaner for clean test state [https://github.com/DatabaseCleaner/database_cleaner]
  gem "database_cleaner-active_record"

  # Shoulda matchers for testing [https://github.com/thoughtbot/shoulda-matchers]
  gem "shoulda-matchers"
  
  # VCR for HTTP interaction recording in tests [https://github.com/vcr/vcr]
  gem "vcr"
  
  # WebMock for stubbing HTTP requests [https://github.com/bblimke/webmock]
  gem "webmock"
  
  # Pundit matchers for authorization testing [https://github.com/punditcommunity/pundit-matchers]
  gem "pundit-matchers"
end