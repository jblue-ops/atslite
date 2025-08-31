# frozen_string_literal: true

class User < ApplicationRecord
  include FullNameable

  # Include Devise modules based on database structure
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable

  # Associations - using organization_id as per database structure
  belongs_to :organization, optional: false
  belongs_to :invited_by, class_name: "User", optional: true
  has_many :invitations, class_name: "User", foreign_key: "invited_by_id", dependent: :nullify

  # Nested attributes for organization creation during signup
  accepts_nested_attributes_for :organization

  # ATS-specific associations
  has_many :assigned_applications, class_name: "Application", foreign_key: "assigned_recruiter_id", dependent: :nullify
  has_many :referrals, class_name: "Application", foreign_key: "referrer_id", dependent: :nullify
  has_many :organized_interviews, class_name: "Interview", foreign_key: "organizer_id",
                                  dependent: :restrict_with_exception
  has_many :conducted_interviews, class_name: "Interview", foreign_key: "primary_interviewer_id",
                                  dependent: :restrict_with_exception
  has_many :managed_jobs, class_name: "Job", foreign_key: "hiring_manager_id", dependent: :restrict_with_exception
  has_many :interview_participations, dependent: :destroy
  has_many :interviews, through: :interview_participations
  has_many :authored_notes, class_name: "Note", foreign_key: "author_id", dependent: :destroy
  has_many :activities, foreign_key: "actor_id", dependent: :destroy
  has_many :sent_communications, class_name: "Communication", foreign_key: "sender_id", dependent: :destroy

  # Validations
  validates :first_name, :last_name, :role, presence: true
  validates :email, presence: true, uniqueness: { scope: :organization_id }
  validates :phone, format: { with: /\A\+?[0-9()\-\s]+\z/, message: "must be a valid phone number" },
                    allow_blank: true
  validates :role, inclusion: { in: %w[admin hiring_manager recruiter interviewer coordinator] }
  validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }
  validate :password_complexity

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_role, ->(role) { where(role: role) }
  scope :admins, -> { where(role: "admin") }
  scope :hiring_managers, -> { where(role: "hiring_manager") }
  scope :recruiters, -> { where(role: "recruiter") }
  scope :interviewers, -> { where(role: "interviewer") }
  scope :coordinators, -> { where(role: "coordinator") }
  scope :verified, -> { where.not(email_verified_at: nil) }
  scope :unverified, -> { where(email_verified_at: nil) }
  scope :recently_active, -> { where("last_sign_in_at > ?", 30.days.ago) }

  # Enums for roles
  enum :role, {
    admin: "admin",
    hiring_manager: "hiring_manager",
    recruiter: "recruiter",
    interviewer: "interviewer",
    coordinator: "coordinator"
  }

  # Callbacks
  before_validation :normalize_email
  before_validation :set_default_timezone
  after_create :set_default_permissions

  # Multi-tenant support
  acts_as_tenant :organization

  # Instance methods
  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :account_inactive
  end

  def can_manage_users?
    admin?
  end

  def can_manage_jobs?
    admin? || hiring_manager?
  end

  def can_interview?
    admin? || hiring_manager? || interviewer?
  end

  def can_recruit?
    admin? || hiring_manager? || recruiter?
  end

  def can_coordinate?
    admin? || coordinator?
  end

  def has_permission?(permission)
    permissions.include?(permission.to_s)
  end

  def grant_permission!(permission)
    update!(permissions: permissions.union([permission.to_s]))
  end

  def revoke_permission!(permission)
    update!(permissions: permissions - [permission.to_s])
  end

  def update_last_activity!
    update_column(:last_sign_in_at, Time.current) if persisted?
  end

  def deactivate!
    update!(active: false)
  end

  def activate!
    update!(active: true)
  end

  def invite!(inviter)
    update!(invited_by: inviter, invited_at: Time.current)
  end

  def display_time_zone
    ActiveSupport::TimeZone[time_zone] || ActiveSupport::TimeZone["UTC"]
  end

  private

  def normalize_email
    self.email = email.to_s.downcase.strip if email.present?
  end

  def set_default_timezone
    self.time_zone ||= "UTC"
  end

  def password_complexity
    return if password.blank?

    # Check for minimum complexity requirements
    unless password.match?(/\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}\z/)
      errors.add :password, "must contain at least one lowercase letter, one uppercase letter, and one number"
    end

    # Check for common weak passwords
    weak_passwords = %w[password password123 123456789 qwerty admin]
    if weak_passwords.include?(password.downcase)
      errors.add :password, "is too common. Please choose a more secure password"
    end

    # Check if password contains personal information
    if password.downcase.include?(first_name.to_s.downcase) || password.downcase.include?(last_name.to_s.downcase)
      errors.add :password, "should not contain your name"
    end

    return unless email.present? && password.downcase.include?(email.split("@").first.downcase)

    errors.add :password, "should not contain part of your email address"
  end

  def set_default_permissions
    return unless persisted?

    default_permissions = case role
                          when "admin"
                            %w[manage_users manage_jobs manage_candidates view_analytics]
                          when "hiring_manager"
                            %w[manage_jobs view_candidates view_analytics]
                          when "recruiter"
                            %w[manage_candidates schedule_interviews]
                          when "interviewer"
                            %w[view_candidates provide_feedback]
                          when "coordinator"
                            %w[schedule_interviews manage_communications]
                          else
                            []
                          end

    update_column(:permissions, default_permissions)
  end
end
