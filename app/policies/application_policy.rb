# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user.present?
  end

  def show?
    user.present? && same_organization?
  end

  def create?
    user.present?
  end

  def new?
    create?
  end

  def update?
    user.present? && same_organization?
  end

  def edit?
    update?
  end

  def destroy?
    user.present? && same_organization?
  end

  protected

  # Check if the current user and record belong to the same organization
  def same_organization?
    return true unless record.respond_to?(:organization_id)
    return true unless user.respond_to?(:organization_id)

    user.organization_id == record.organization_id
  end

  # Check if user has admin privileges
  def admin?
    user.admin?
  end

  # Check if user has hiring manager privileges
  def hiring_manager?
    user.admin? || user.hiring_manager?
  end

  # Check if user has recruiter privileges
  def recruiter?
    user.admin? || user.hiring_manager? || user.recruiter?
  end

  # Check if user can interview
  def interviewer?
    user.admin? || user.hiring_manager? || user.interviewer?
  end

  # Check if user can coordinate
  def coordinator?
    user.admin? || user.coordinator?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none if user.blank?

      # Multi-tenant scoping - users can only see records from their organization
      if scope.respond_to?(:where) && scope.klass.column_names.include?("organization_id")
        scope.where(organization_id: user.organization_id)
      else
        scope.all
      end
    end

    private

    attr_reader :user, :scope
  end
end
