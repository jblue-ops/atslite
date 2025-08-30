# frozen_string_literal: true

class JobPolicy < ApplicationPolicy
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

    # Admin can edit any job in their organization
    return true if admin?

    # Users can edit jobs they are the hiring manager for
    job_owner?
  end

  def edit?
    update?
  end

  def destroy?
    return false unless user.present? && same_organization?

    # Admin can delete any job in their organization
    return true if admin?

    # Users can delete jobs they are the hiring manager for
    job_owner?
  end

  # State transition permissions
  def publish?
    return false unless user.present? && same_organization?
    return false unless record.can_be_published?

    # Admin can publish any job in their organization
    return true if admin?

    # Users can publish jobs they are the hiring manager for
    job_owner?
  end

  def close?
    return false unless user.present? && same_organization?
    return false unless record.published?

    # Admin can close any job in their organization
    return true if admin?

    # Users can close jobs they are the hiring manager for
    job_owner?
  end

  def reopen?
    return false unless user.present? && same_organization?
    return false unless record.closed?

    # Admin can reopen any job in their organization
    return true if admin?

    # Users can reopen jobs they are the hiring manager for
    job_owner?
  end

  def archive?
    return false unless user.present? && same_organization?

    # Admin can archive any job in their organization
    return true if admin?

    # Users can archive jobs they are the hiring manager for
    job_owner?
  end

  def unarchive?
    return false unless user.present? && same_organization?
    return false unless record.archived?

    # Admin can unarchive any job in their organization
    return true if admin?

    # Users can unarchive jobs they are the hiring manager for
    job_owner?
  end

  # View permissions for different aspects of the job
  def view_analytics?
    return false unless user.present? && same_organization?

    # Admin, hiring managers, and recruiters can view job analytics
    admin? || hiring_manager? || recruiter?
  end

  def view_applications?
    return false unless user.present? && same_organization?

    # Anyone who can recruit or manage jobs can view applications
    user.can_recruit? || admin?
  end

  def manage_applications?
    return false unless user.present? && same_organization?

    # Admin can manage any job's applications
    return true if admin?

    # Users can manage applications for jobs they are the hiring manager for
    job_owner? || user.can_recruit?
  end

  private

  def job_owner?
    record.hiring_manager_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?

      # Multi-tenant scoping - users can only see jobs from their organization
      scoped_jobs = scope.where(organization_id: user.organization_id)

      # Further filtering based on role permissions
      case user.role
      when "admin", "hiring_manager"
        # Admins and hiring managers can see all jobs in their organization
        scoped_jobs
      when "recruiter"
        # Recruiters can see all published jobs and jobs they're involved with
        scoped_jobs.where(status: %w[published closed])
      when "interviewer", "coordinator"
        # Interviewers and coordinators can see published jobs they might need to work with
        scoped_jobs.published
      else
        # Default to no access for unknown roles
        scoped_jobs.none
      end
    end
  end
end
