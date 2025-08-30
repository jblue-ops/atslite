# VCR configuration for external API testing
require "vcr"

VCR.configure do |config|
  # Store cassettes in spec/fixtures/vcr_cassettes
  config.cassette_library_dir = Rails.root.join("spec", "fixtures", "vcr_cassettes")

  # Use WebMock as the HTTP stubbing library
  config.hook_into :webmock

  # Configure request matching
  config.default_cassette_options = {
    match_requests_on: %i[method uri headers body],
    record: :once,
    allow_unused_http_interactions: false
  }

  # Ignore localhost requests (for testing with local services)
  config.ignore_localhost = true

  # Ignore requests to test server
  config.ignore_hosts "localhost", "127.0.0.1", "0.0.0.0"

  # Filter sensitive data
  config.filter_sensitive_data("<API_KEY>") { ENV.fetch("API_KEY", nil) }
  config.filter_sensitive_data("<SECRET_KEY>") { ENV.fetch("SECRET_KEY", nil) }
  config.filter_sensitive_data("<DATABASE_URL>") { ENV.fetch("DATABASE_URL", nil) }
  config.filter_sensitive_data("<REDIS_URL>") { ENV.fetch("REDIS_URL", nil) }

  # Filter authentication tokens
  config.filter_sensitive_data("<ACCESS_TOKEN>") do |interaction|
    auth_header = interaction.request.headers["Authorization"]&.first
    auth_header&.gsub(/Bearer\s+/, "")
  end

  # Filter API keys from query parameters
  config.filter_sensitive_data("<FILTERED_API_KEY>") do |interaction|
    URI.decode_www_form(URI(interaction.request.uri).query || "").to_h["api_key"]
  end

  # Configure for different environments
  config.configure_rspec_metadata!

  # Allow HTTP connections when VCR is turned off
  config.allow_http_connections_when_no_cassette = false

  # Debug mode - uncomment for debugging HTTP interactions
  # config.debug_logger = File.open(Rails.root.join('log', 'vcr.log'), 'w')
end

# WebMock configuration
require "webmock/rspec"

WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: [
    "chromedriver.storage.googleapis.com",  # For Selenium Chrome driver downloads
    "github.com",                           # For CI/CD
    "api.github.com"                        # For CI/CD
  ]
)

RSpec.configure do |config|
  # Metadata-based VCR integration
  # Use :vcr tag to automatically use VCR for a test
  config.around(:each, :vcr) do |example|
    name = example.metadata[:full_description]
      .split(/\s+/, 2)
      .join("/")
      .underscore
      .gsub(%r{[^\w/]+}, "_")

    options = example.metadata.slice(:record, :match_requests_on, :allow_unused_http_interactions)

    VCR.use_cassette(name, options) do
      example.run
    end
  end

  # Automatically use VCR for tests that make external requests
  config.before(:each, :external_api) do
    VCR.insert_cassette(
      RSpec.current_example.metadata[:full_description].underscore.gsub(/[^\w]+/, "_"),
      record: :once
    )
  end

  config.after(:each, :external_api) do
    VCR.eject_cassette
  end

  # Helper to stub external service calls
  config.before(:each, :stub_external) do
    # Stub common external services used in ATS
    stub_request(:post, /api\.emailservice\.com/)
      .to_return(status: 200, body: '{"status": "sent"}', headers: {})

    stub_request(:post, /hooks\.slack\.com/)
      .to_return(status: 200, body: "ok", headers: {})

    stub_request(:get, /api\.jobboard\.com/)
      .to_return(status: 200, body: '{"jobs": []}', headers: {})
  end
end

# Custom helpers for VCR usage
module VCRHelpers
  # Use VCR cassette for a block of code
  def with_vcr_cassette(name, options = {}, &)
    VCR.use_cassette(name, options, &)
  end

  # Record new interactions for a cassette
  def record_vcr_cassette(name, &)
    VCR.use_cassette(name, record: :new_episodes, &)
  end

  # Stub external API responses for testing
  def stub_external_api_success(url_pattern, response_body = {})
    stub_request(:any, url_pattern)
      .to_return(
        status: 200,
        body: response_body.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_external_api_failure(url_pattern, status = 500)
    stub_request(:any, url_pattern)
      .to_return(
        status: status,
        body: { error: "Internal Server Error" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end

RSpec.configure do |config|
  config.include VCRHelpers
end
