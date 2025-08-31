# frozen_string_literal: true

class Organization < ApplicationRecord
  # Multi-tenant root model
  has_many :users, dependent: :destroy
  has_many :jobs, dependent: :destroy
  has_many :job_templates, dependent: :destroy
  has_many :departments, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :communications, dependent: :destroy
  has_many :activities, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :website_url,
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
  validates :industry, length: { maximum: 50 }, allow_blank: true
  validates :size_category, inclusion: { in: %w[startup small medium large enterprise] }, allow_blank: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_industry, ->(industry) { where(industry: industry) }
  scope :by_size, ->(size) { where(size_category: size) }

  # Enums for size categories
  enum :size_category, {
    startup: "startup",
    small: "small",
    medium: "medium",
    large: "large",
    enterprise: "enterprise"
  }, suffix: :size

  # Callbacks
  before_validation :normalize_website_url
  before_create :set_default_settings

  # Instance methods
  def display_name
    name.presence || "Unnamed Organization"
  end

  def user_count
    users.active.count
  end

  def job_count
    jobs.count
  end

  def deactivate!
    update!(active: false)
  end

  def activate!
    update!(active: true)
  end

  def setting(key)
    settings[key.to_s]
  end

  def set_setting!(key, value)
    self.settings = settings.merge(key.to_s => value)
    save!
  end

  def remove_setting!(key)
    self.settings = settings.except(key.to_s)
    save!
  end

  def admin_users
    users.admins.active
  end

  def hiring_managers
    users.hiring_managers.active
  end

  def recruiters
    users.recruiters.active
  end

  def subscription_tier
    setting("subscription_tier") || "starter"
  end

  def subscription_active?
    active? && (setting("subscription_ends_at").blank? ||
                DateTime.parse(setting("subscription_ends_at")) > Time.current)
  end

  def trial_active?
    setting("trial_ends_at").present? &&
      DateTime.parse(setting("trial_ends_at")) > Time.current
  end

  def can_add_user?
    case subscription_tier
    when "starter"
      user_count < 5
    when "professional"
      user_count < 25
    when "enterprise"
      true
    else
      user_count < 3 # Free tier
    end
  end

  def can_add_job?
    case subscription_tier
    when "starter"
      job_count < 10
    when "professional"
      job_count < 100
    when "enterprise"
      true
    else
      job_count < 2 # Free tier
    end
  end

  private

  def normalize_website_url
    return if website_url.blank?

    return if website_url.start_with?("http://", "https://")

    self.website_url = "https://#{website_url}"
  end

  def set_default_settings
    self.settings ||= {
      "subscription_tier" => "starter",
      "trial_ends_at" => 30.days.from_now.iso8601,
      "email_notifications" => true,
      "candidate_data_retention_days" => 365,
      "require_two_factor" => false
    }
  end
end
