# frozen_string_literal: true

class JobPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.super_admin?
        scope.all
      else
        scope.where(organization: user.organization)
      end
    end
  end

  def index?
    user_can_access_jobs?
  end

  def search?
    user_can_access_jobs?
  end

  def show?
    return false unless user_can_access_jobs?
    return true if user.admin? || user.super_admin?

    same_organization?
  end

  def new?
    user_can_create_jobs?
  end

  def create?
    return false unless user_can_create_jobs?
    return false unless same_organization?

    true
  end

  def edit?
    return false unless user_can_manage_jobs?
    return true if user.admin? || user.super_admin?

    same_organization? && (owns_job? || can_manage_all_jobs?)
  end

  def update?
    edit?
  end

  def destroy?
    return false unless user_can_manage_jobs?
    return true if user.admin? || user.super_admin?

    same_organization? && (owns_job? || can_manage_all_jobs?)
  end

  def publish?
    return false unless user_can_manage_jobs?
    return false unless record.can_be_published?

    update?
  end

  def close?
    return false unless user_can_manage_jobs?
    return false unless record.published?

    update?
  end

  def reopen?
    return false unless user_can_manage_jobs?
    return false unless record.closed?

    update?
  end

  def archive?
    return false unless user_can_manage_jobs?

    update?
  end

  def unarchive?
    return false unless user_can_manage_jobs?
    return false unless record.archived?

    update?
  end

  private

  def user_can_access_jobs?
    user.can_view_jobs?
  end

  def user_can_create_jobs?
    user.can_create_jobs?
  end

  def user_can_manage_jobs?
    user.can_manage_jobs?
  end

  def same_organization?
    record.organization_id == user.organization_id
  end

  def owns_job?
    record.hiring_manager_id == user.id
  end

  def can_manage_all_jobs?
    user.admin? || user.super_admin? || user.hiring_manager?
  end
end
