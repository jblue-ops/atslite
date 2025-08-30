class HomeController < ApplicationController
  def index
    redirect_to dashboard_path if user_signed_in?
  end

  private

  def dashboard_path
    # For now, redirect to a placeholder dashboard
    # This will be replaced with actual dashboard routes later
    if current_user&.admin?
      "/admin/dashboard"
    elsif current_user&.hiring_manager?
      "/hiring_manager/dashboard"
    else
      "/recruiter/dashboard"
    end
  end
end
