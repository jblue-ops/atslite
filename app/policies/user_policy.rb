# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    return true if user == record # Users can view their own profile

    admin? && same_organization? # Only admins can view other users in same organization
  end

  def create?
    admin?
  end

  def update?
    return true if user == record # Users can update their own profile

    admin? && same_organization? # Only admins can update other users in same organization
  end

  def destroy?
    return false if user == record # Users cannot delete themselves

    admin? && same_organization? && record != record.organization.users.admins.first # Cannot delete the first admin
  end

  def activate?
    admin? && user != record && same_organization?
  end

  def deactivate?
    admin? && user != record && same_organization?
  end

  def change_role?
    admin? && user != record && same_organization?
  end

  def invite?
    admin? || hiring_manager?
  end

  def manage_permissions?
    admin?
  end

  def impersonate?
    admin? && user != record
  end

  # Permission-based authorization methods
  def view_analytics?
    user.has_permission?("view_analytics")
  end

  def manage_jobs?
    user.has_permission?("manage_jobs")
  end

  def manage_candidates?
    user.has_permission?("manage_candidates")
  end

  def schedule_interviews?
    user.has_permission?("schedule_interviews")
  end

  def provide_feedback?
    user.has_permission?("provide_feedback")
  end

  def manage_communications?
    user.has_permission?("manage_communications")
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      # Admins can see all users in their organization
      if user.admin?
        scope.where(organization_id: user.organization_id)
      else
        # Non-admins can only see themselves
        scope.where(id: user.id)
      end
    end
  end
end
