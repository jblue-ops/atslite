# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id            :uuid             not null, primary key
#  company_id    :uuid             not null
#  email         :string           not null
#  first_name    :string           not null
#  last_name     :string           not null
#  role          :integer          default("readonly"), not null
#  settings      :jsonb            not null
#  last_login_at :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_users_on_company_and_email     (company_id,email) UNIQUE
#  index_users_on_company_and_role      (company_id,role)
#  index_users_on_company_id            (company_id)
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_full_name             (first_name,last_name)
#  index_users_on_last_login_at         (last_login_at)
#  index_users_on_role                  (role)
#  index_users_on_settings              (settings) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#

class User < ApplicationRecord
  include FullNameable

  # Associations
  belongs_to :company
  
  # Interview relationships
  has_many :interviews_as_interviewer, class_name: 'Interview', foreign_key: 'interviewer_id', dependent: :nullify
  has_many :interviews_scheduled_by_me, class_name: 'Interview', foreign_key: 'scheduled_by_id', dependent: :nullify
  has_many :applications_stage_changed_by_me, class_name: 'Application', foreign_key: 'stage_changed_by_id', dependent: :nullify

  # ActiveStorage attachments
  has_one_attached :avatar

  # Enums
  enum :role, {
    readonly: 0,
    interviewer: 1,
    recruiter: 2,
    admin: 3
  }, prefix: true

  # Validations
  validates :email, presence: true, uniqueness: { scope: :company_id, case_sensitive: false }
  validates :email, format: { 
    with: URI::MailTo::EMAIL_REGEXP, 
    message: 'must be a valid email address' 
  }
  validates :first_name, presence: true, length: { minimum: 1, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 1, maximum: 50 }
  validates :role, presence: true
  validates :settings, presence: true
  validates :company_id, presence: true

  validate :email_domain_matches_company, if: -> { company&.email_domain.present? }
  validate :avatar_content_type, if: -> { avatar.attached? }
  validate :avatar_file_size, if: -> { avatar.attached? }

  # Callbacks
  before_validation :normalize_email
  before_validation :normalize_names
  before_save :update_last_login_if_needed

  # Scopes
  scope :active, -> { where('last_login_at > ?', 30.days.ago) }
  scope :inactive, -> { where('last_login_at <= ? OR last_login_at IS NULL', 30.days.ago) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_role, ->(role) { where(role: role) }
  scope :with_recent_activity, -> { where('last_login_at > ?', 7.days.ago) }
  scope :for_company, ->(company) { where(company: company) }

  # Delegations
  delegate :name, to: :company, prefix: true, allow_nil: true
  delegate :subscription_plan, to: :company, prefix: true, allow_nil: true

  # Class methods
  def self.search(query)
    return none if query.blank?

    query = query.strip.downcase
    where('LOWER(email) LIKE ? OR LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ?', 
          "%#{query}%", "%#{query}%", "%#{query}%")
  end

  def self.by_permission_level(level)
    case level.to_s
    when 'basic'
      where.not(role: :readonly)
    when 'advanced'
      where(role: [:recruiter, :admin])
    when 'admin'
      admin
    else
      none
    end
  end

  def self.find_by_email_and_company(email, company)
    find_by(email: email.downcase.strip, company: company)
  end

  # Instance methods
  def can_manage_users?
    role_admin?
  end

  def can_manage_interviews?
    role_admin? || role_recruiter?
  end

  def can_conduct_interviews?
    role_admin? || role_recruiter? || role_interviewer?
  end

  def can_view_reports?
    role_admin? || role_recruiter?
  end

  def active?
    last_login_at.present? && last_login_at > 30.days.ago
  end

  def recently_active?
    last_login_at.present? && last_login_at > 7.days.ago
  end

  def setting(key)
    settings[key.to_s]
  end

  def update_setting(key, value)
    settings[key.to_s] = value
    save!
  end

  def avatar_url(variant: :thumb)
    return nil unless avatar.attached?
    
    case variant
    when :thumb
      Rails.application.routes.url_helpers.rails_representation_url(
        avatar.variant(resize_to_limit: [100, 100]), 
        only_path: true
      )
    when :medium
      Rails.application.routes.url_helpers.rails_representation_url(
        avatar.variant(resize_to_limit: [300, 300]), 
        only_path: true
      )
    else
      Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: true)
    end
  end

  def initials_color
    # Generate a consistent color based on the user's initials
    colors = %w[#1f77b4 #ff7f0e #2ca02c #d62728 #9467bd #8c564b #e377c2 #7f7f7f #bcbd22 #17becf]
    colors[id.to_s.sum % colors.length]
  end

  def login!
    update_column(:last_login_at, Time.current)
  end

  def deactivate!
    update_column(:last_login_at, nil)
  end

  def belongs_to_company?(company)
    self.company == company
  end

  private

  def normalize_email
    self.email = email&.downcase&.strip
  end

  def normalize_names
    self.first_name = first_name&.strip&.titleize if first_name.present?
    self.last_name = last_name&.strip&.titleize if last_name.present?
  end

  def update_last_login_if_needed
    # This will be used later with authentication system
    # Currently just ensures the field can be set manually
  end

  def email_domain_matches_company
    return unless company&.email_domain.present? && email.present?
    
    user_domain = email.split('@').last&.downcase
    return if user_domain == company.email_domain.downcase

    errors.add(:email, "must be from the #{company.email_domain} domain")
  end

  def avatar_content_type
    acceptable_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
    return if acceptable_types.include?(avatar.content_type)

    errors.add(:avatar, 'must be a JPEG, PNG, or WebP image')
  end

  def avatar_file_size
    return unless avatar.blob.byte_size > 2.megabytes

    errors.add(:avatar, 'must be less than 2MB')
  end
end