# frozen_string_literal: true

# SimpleCov initialization for Rails application
# This initializer ensures SimpleCov is properly configured
# when running in test environment with coverage enabled

if Rails.env.test? && (ENV["COVERAGE"] || ENV["CI"])
  require "simplecov"

  # Load SimpleCov configuration
  SimpleCov.load_profile "rails" if defined?(SimpleCov)
  
  # Additional Rails-specific configuration
  SimpleCov.configure do
    # Add Rails-specific filters
    add_filter "app/channels/application_cable/"
    add_filter "app/jobs/application_job.rb"
    add_filter "app/mailers/application_mailer.rb"
    add_filter "app/models/application_record.rb"
    add_filter "app/controllers/application_controller.rb"
    
    # Filter out Rails generators and templates
    add_filter %r{^/app/views/.*\.html\.erb$} # Skip ERB templates from coverage
    add_filter %r{^/config/}
    add_filter %r{^/db/}
    add_filter %r{^/lib/tasks/}
    
    # Coverage tracking for Rails engines and concerns
    track_files "app/**/*.rb"
    track_files "lib/**/*.rb"
  end
  
  # Start SimpleCov
  SimpleCov.start if defined?(SimpleCov)
end