# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
# Uncomment the line below in case you have `--require rails_helper` in the `.rspec` file
# that will avoid rails generators crashing because migrations haven't been run yet
# return unless Rails.env.test?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

# Shoulda Matchers configuration
require 'shoulda/matchers'

# FactoryBot configuration
require 'factory_bot_rails'

# Database Cleaner configuration
require 'database_cleaner/active_record'

# SimpleCov for test coverage
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/vendor/'
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/db/'
  
  add_group 'Models', 'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Services', 'app/services'
  add_group 'Jobs', 'app/jobs'
  add_group 'Mailers', 'app/mailers'
  add_group 'Helpers', 'app/helpers'
  add_group 'Policies', 'app/policies'
end if ENV['COVERAGE']

# Load all support files
Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

# Ensures that the test database schema matches the current schema file.
# If there are pending migrations it will invoke `db:test:prepare` to
# recreate the test database by loading the schema.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # Database transaction strategy
  config.use_transactional_fixtures = false
  
  # Test performance tracking
  config.profile_examples = 10 if ENV['PROFILE']
  
  # Fail fast option
  config.fail_fast = true if ENV['FAIL_FAST']
  
  # Random order testing
  config.order = :random
  Kernel.srand config.seed

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails uses metadata to mix in different behaviours to your tests,
  # for example enabling you to call `get` and `post` in request specs. e.g.:
  #
  #     RSpec.describe UsersController, type: :request do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://rspec.info/features/8-0/rspec-rails
  #
  # You can also this infer these behaviours automatically by location, e.g.
  # /spec/models would pull in the same behaviour as `type: :model` but this
  # behaviour is considered legacy and will be removed in a future version.
  #
  # To enable this behaviour uncomment the line below.
  # config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods

  # Database Cleaner configuration
  config.before(:suite) do
    # Clean database completely before test suite
    DatabaseCleaner.clean_with(:truncation)
    
    # Setup test environment
    Rails.application.load_seed if Rails.env.test?
  end
  
  config.before(:each) do |example|
    # Use transaction strategy for most tests
    DatabaseCleaner.strategy = :transaction
    
    # Use truncation for tests that use JavaScript or multiple threads
    if example.metadata[:js] || example.metadata[:type] == :system || example.metadata[:truncation]
      DatabaseCleaner.strategy = :truncation
    end
    
    DatabaseCleaner.start
  end
  
  config.after(:each) do
    DatabaseCleaner.clean
  end
  
  # Multi-tenant configuration
  config.before(:each) do |example|
    # Set default tenant for multi-tenant tests
    if example.metadata[:tenant]
      ActsAsTenant.current_tenant = example.metadata[:tenant]
    elsif example.metadata[:type] != :system
      # Create a default organization for tests that need it
      organization = create(:organization) if defined?(FactoryBot)
      ActsAsTenant.current_tenant = organization if organization
    end
  end
  
  config.after(:each) do
    ActsAsTenant.current_tenant = nil
  end

  # Shoulda Matchers configuration
  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end
  
  # ActiveJob test configuration
  config.include ActiveJob::TestHelper, type: :job
  
  # ActionMailer test configuration
  config.include ActionMailer::TestHelper, type: :mailer
  
  # Custom test helpers
  config.include ActiveSupport::Testing::TimeHelpers
  
  # Pundit test helpers (commented out for now)
  # config.include Pundit::RSpec::DSL if defined?(Pundit)
  
  # System test configuration
  config.before(:each, type: :system) do
    driven_by :rack_test
  end
  
  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
  end
  
  # Performance testing configuration
  config.before(:each, performance: true) do
    # Setup performance monitoring
    GC.start
    GC.disable
  end
  
  config.after(:each, performance: true) do
    GC.enable
    GC.start
  end
  
  # Parallel testing configuration
  if ENV['PARALLEL']
    config.before(:suite) do
      # Setup for parallel testing
      DatabaseCleaner.clean_with(:truncation)
    end
    
    config.around(:each) do |example|
      # Use truncation for parallel tests to avoid conflicts
      DatabaseCleaner.strategy = :truncation
      DatabaseCleaner.cleaning do
        example.run
      end
    end
  end
  
  # Email delivery configuration for tests
  config.before(:each) do
    ActionMailer::Base.deliveries.clear
  end
  
  # Background job configuration for tests
  # config.before(:each) do
  #   clear_enqueued_jobs
  #   clear_performed_jobs
  # end
  
  # Custom example metadata
  config.define_derived_metadata(file_path: Regexp.new('/spec/models/')) do |metadata|
    metadata[:type] = :model
  end
  
  config.define_derived_metadata(file_path: Regexp.new('/spec/controllers/')) do |metadata|
    metadata[:type] = :controller
  end
  
  config.define_derived_metadata(file_path: Regexp.new('/spec/requests/')) do |metadata|
    metadata[:type] = :request
  end
  
  config.define_derived_metadata(file_path: Regexp.new('/spec/system/')) do |metadata|
    metadata[:type] = :system
  end
  
  config.define_derived_metadata(file_path: Regexp.new('/spec/services/')) do |metadata|
    metadata[:type] = :service
  end
  
  config.define_derived_metadata(file_path: Regexp.new('/spec/jobs/')) do |metadata|
    metadata[:type] = :job
  end
  
  config.define_derived_metadata(file_path: Regexp.new('/spec/mailers/')) do |metadata|
    metadata[:type] = :mailer
  end
  
  # Custom formatters
  if ENV['DETAILED']
    config.default_formatter = 'doc'
  end
  
  # Timeout configuration for slow tests
  config.around(:each, slow: true) do |example|
    timeout = example.metadata[:timeout] || 30
    Timeout.timeout(timeout) do
      example.run
    end
  end
  
  # Infer spec types from file location
  config.infer_spec_type_from_file_location!
  
  # Filter examples by tags
  config.filter_run_when_matching :focus
  config.run_all_when_everything_filtered = true
  
  # Exclude external API tests by default
  config.filter_run_excluding :external_api unless ENV['RUN_EXTERNAL_API_TESTS']
  config.filter_run_excluding :slow unless ENV['RUN_SLOW_TESTS']
end

# Custom RSpec configuration for ATS
module ATSTestHelpers
  def current_organization
    ActsAsTenant.current_tenant
  end

  # Alias for backward compatibility with existing tests
  alias_method :current_company, :current_organization
  
  def with_current_user(user)
    original_user = @current_user
    @current_user = user
    yield
  ensure
    @current_user = original_user
  end
  
  def travel_to_business_day(time = nil)
    time ||= 1.week.from_now
    # Ensure we're on a business day (Monday-Friday)
    while time.saturday? || time.sunday?
      time += 1.day
    end
    travel_to(time)
    time
  end
  
  def expect_audit_log(action, resource = nil)
    expect(PublicActivity::Activity).to receive(:create!).with(
      hash_including(
        trackable: resource,
        key: action
      )
    )
  end
  
  def expect_notification_sent(type, recipient)
    expect {
      yield
    }.to change { recipient.notifications.where(notification_type: type).count }.by(1)
  end
end

RSpec.configure do |config|
  config.include ATSTestHelpers
end
