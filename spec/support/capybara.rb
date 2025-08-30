# Capybara configuration for system tests
require "capybara/rails"
require "capybara/rspec"

Capybara.configure do |config|
  # Use Chrome headless by default
  config.default_driver = :rack_test
  config.javascript_driver = :selenium_chrome_headless

  # Server configuration
  config.server_host = "localhost"
  config.server_port = 3001

  # Wait times
  config.default_max_wait_time = 5
  config.default_normalize_ws = true

  # Save screenshots and HTML on failure
  config.save_path = Rails.root.join("tmp", "capybara", "capybara")

  # Automatic screenshot on failure
  config.automatic_label_click = false

  # Asset host for system tests
  config.asset_host = "http://localhost:3001" if Rails.env.test?
end

# Configure Chrome options for headless testing
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-gpu")
  options.add_argument("--window-size=1400,1400")
  options.add_argument("--remote-debugging-port=9222")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# Configure Chrome with full browser for debugging
Capybara.register_driver :selenium_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--no-sandbox")
  options.add_argument("--window-size=1400,1400")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

RSpec.configure do |config|
  # Clean up Capybara after each test
  config.after(:each, type: :system) do
    Capybara.reset_sessions!
  end

  # Include Capybara DSL in system specs
  config.include Capybara::DSL, type: :system

  # Configure screenshot taking on failures
  config.after(:each, type: :system) do |example|
    if example.exception
      meta = example.metadata
      filename = File.basename(meta[:file_path])
      line_number = meta[:line_number]
      screenshot_name = "#{filename}-#{line_number}.png"
      screenshot_path = "tmp/screenshots/#{screenshot_name}"

      FileUtils.mkdir_p("tmp/screenshots")
      page.save_screenshot(screenshot_path)

      puts "\n  Screenshot saved to #{screenshot_path}"
    end
  end
end
