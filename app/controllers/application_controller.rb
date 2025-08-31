# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Ensure user is authenticated before accessing protected resources
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Pundit authorization checks
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  # Pundit error handling
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,
                                      keys: [:first_name, :last_name, :phone, :time_zone,
                                             { organization_attributes: %i[name domain industry] }])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[first_name last_name phone time_zone])
  end

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end
end
