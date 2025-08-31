# frozen_string_literal: true

class JobTemplatePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && same_organization?
  end

  def create?
    user.present? && user.can_manage_jobs?
  end

  def new?
    create?
  end

  def update?
    return false unless user.present? && same_organization?

    # Admin can edit any template in their organization
    return true if admin?

    # Users can edit templates they created
    template_creator?
  end

  def edit?
    update?
  end

  def destroy?
    return false unless user.present? && same_organization?

    # Admin can delete any template in their organization
    return true if admin?

    # Users can delete templates they created if not widely used
    template_creator? && record.usage_count < 5
  end

  # Template management permissions
  def activate?
    return false unless user.present? && same_organization?

    # Admin can activate any template in their organization
    return true if admin?

    # Users can activate templates they created
    template_creator?
  end

  def deactivate?
    return false unless user.present? && same_organization?

    # Admin can deactivate any template in their organization
    return true if admin?

    # Users can deactivate templates they created
    template_creator?
  end

  def use?
    return false unless user.present? && same_organization?
    return false unless record.is_active?

    # Any user who can create jobs can use active templates
    user.can_manage_jobs?
  end

  # View permissions for different aspects of the template
  def view_usage_stats?
    return false unless user.present? && same_organization?

    # Admin, hiring managers, and template creators can view usage stats
    admin? || hiring_manager? || template_creator?
  end

  def duplicate?
    return false unless user.present? && same_organization?

    # Any user who can create templates can duplicate existing ones
    user.can_manage_jobs?
  end

  private

  def template_creator?
    record.created_by_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      # Multi-tenant scoping - users can only see templates from their organization
      scoped_templates = scope.where(organization_id: user.organization_id)

      # Further filtering based on role permissions
      case user.role
      when "admin", "hiring_manager"
        # Admins and hiring managers can see all templates in their organization
        scoped_templates
      when "recruiter"
        # Recruiters can see all active templates and templates they created
        scoped_templates.where("is_active = true OR created_by_id = ?", user.id)
      when "interviewer", "coordinator"
        # Interviewers and coordinators can see active templates they might need
        scoped_templates.active
      else
        # Default to no access for unknown roles
        scoped_templates.none
      end
    end
  end
end
