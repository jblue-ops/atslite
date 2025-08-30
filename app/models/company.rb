# frozen_string_literal: true

# == Schema Information
#
# Table name: companies
#
#  id                :uuid             not null, primary key
#  name              :string           not null
#  slug              :string           not null
#  email_domain      :string
#  subscription_plan :integer          default("free"), not null
#  settings          :jsonb            not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_companies_on_email_domain       (email_domain)
#  index_companies_on_name               (name)
#  index_companies_on_settings           (settings) USING gin
#  index_companies_on_slug               (slug) UNIQUE
#  index_companies_on_subscription_plan  (subscription_plan)
#

class Company < ApplicationRecord
  # Associations
  has_many :users, dependent: :destroy
  has_many :jobs, dependent: :destroy
  has_many :applications, dependent: :destroy
  has_many :candidates, through: :applications
  has_many :interviews, through: :applications

  # ActiveStorage attachments
  has_one_attached :logo

  # Enums
  enum :subscription_plan, {
    free: 0,
    professional: 1,
    enterprise: 2
  }, prefix: true

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :slug, presence: true, uniqueness: true, length: { minimum: 2, maximum: 50 }
  validates :slug, format: { 
    with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, 
    message: 'must contain only lowercase letters, numbers, and hyphens' 
  }
  validates :email_domain, format: { 
    with: /\A[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}\z/, 
    message: 'must be a valid domain format' 
  }, allow_blank: true
  validates :subscription_plan, presence: true
  validates :settings, presence: true

  validate :logo_content_type, if: -> { logo.attached? }
  validate :logo_file_size, if: -> { logo.attached? }

  # Callbacks
  before_validation :normalize_slug
  before_validation :normalize_email_domain

  # Scopes
  scope :by_subscription_plan, ->(plan) { where(subscription_plan: plan) }
  scope :with_email_domain, -> { where.not(email_domain: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :alphabetical, -> { order(:name) }
  scope :active, -> { joins(:users).distinct }

  # Class methods
  def self.find_by_domain(domain)
    find_by(email_domain: domain)
  end

  def self.search(query)
    where('name ILIKE ? OR slug ILIKE ?', "%#{query}%", "%#{query}%")
  end

  # Instance methods
  def display_name
    name
  end

  def to_param
    slug
  end

  def user_count
    users.count
  end

  def active_users
    users.where('last_login_at > ?', 30.days.ago)
  end

  def admin_users
    users.admin
  end

  def can_add_users?
    case subscription_plan
    when 'free'
      user_count < 5
    when 'professional'
      user_count < 50
    when 'enterprise'
      true
    end
  end

  def setting(key)
    settings[key.to_s]
  end

  def update_setting(key, value)
    settings[key.to_s] = value
    save!
  end

  def logo_url
    return nil unless logo.attached?
    
    Rails.application.routes.url_helpers.rails_blob_url(logo, only_path: true)
  end

  private

  def normalize_slug
    return unless slug.present?
    
    self.slug = slug.downcase.strip.gsub(/[^a-z0-9\-]/, '-').gsub(/-+/, '-').gsub(/^-|-$/, '')
  end

  def normalize_email_domain
    return unless email_domain.present?
    
    self.email_domain = email_domain.downcase.strip
  end

  def logo_content_type
    acceptable_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
    return if acceptable_types.include?(logo.content_type)

    errors.add(:logo, 'must be a JPEG, PNG, or WebP image')
  end

  def logo_file_size
    return unless logo.blob.byte_size > 5.megabytes

    errors.add(:logo, 'must be less than 5MB')
  end
end