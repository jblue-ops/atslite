# Authentication helpers for testing user sessions
module AuthenticationHelpers
  # Sign in a user for controller and request specs
  def sign_in(user = nil)
    user ||= create(:user)
    sign_in user, scope: :user
    user
  end

  # Sign in as admin user
  def sign_in_as_admin(admin_user = nil)
    admin_user ||= create(:user, :admin)
    sign_in admin_user, scope: :user
    admin_user
  end

  # Sign in as recruiter
  def sign_in_as_recruiter(recruiter = nil)
    recruiter ||= create(:user, :recruiter)
    sign_in recruiter, scope: :user
    recruiter
  end

  # Sign in as interviewer
  def sign_in_as_interviewer(interviewer = nil)
    interviewer ||= create(:user, :interviewer)
    sign_in interviewer, scope: :user
    interviewer
  end

  # Sign out current user
  def sign_out_user
    sign_out :user
  end

  # Create authentication headers for API requests
  def auth_headers(user = nil)
    user ||= create(:user)
    token = user.generate_auth_token # Assumes token-based auth method
    {
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json"
    }
  end

  # Create authentication headers for admin API requests
  def admin_auth_headers(admin_user = nil)
    admin_user ||= create(:user, :admin)
    token = admin_user.generate_auth_token
    {
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json"
    }
  end
end

# System test authentication helpers
module SystemAuthenticationHelpers
  # Sign in through the UI
  def sign_in_user(user = nil, password = "password123")
    user ||= create(:user, password: password, password_confirmation: password)

    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: password
    click_button "Log in"

    expect(page).to have_content("Signed in successfully")
    user
  end

  # Sign in as admin through UI
  def sign_in_admin(admin_user = nil, password = "password123")
    admin_user ||= create(:user, :admin, password: password, password_confirmation: password)

    visit new_user_session_path
    fill_in "Email", with: admin_user.email
    fill_in "Password", with: password
    click_button "Log in"

    expect(page).to have_content("Signed in successfully")
    admin_user
  end

  # Sign out through the UI
  def sign_out_user
    click_link "Sign out"
    expect(page).to have_content("Signed out successfully")
  end

  # Expect to be redirected to sign in page
  def expect_to_be_redirected_to_sign_in
    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_content("You need to sign in or sign up before continuing")
  end

  # Expect access denied
  def expect_access_denied
    expect(page).to have_content("Access denied").or have_content("You are not authorized to perform this action")
  end
end

RSpec.configure do |config|
  # Include Devise test helpers
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system

  # Include our custom authentication helpers
  config.include AuthenticationHelpers, type: :controller
  config.include AuthenticationHelpers, type: :request
  config.include SystemAuthenticationHelpers, type: :system

  # Automatically sign in for feature specs that don't test authentication
  config.before(:each, :authenticated) do
    sign_in_user if defined?(sign_in_user)
  end

  # Automatically sign in as admin for admin specs
  config.before(:each, :admin) do
    sign_in_admin if defined?(sign_in_admin)
  end
end
