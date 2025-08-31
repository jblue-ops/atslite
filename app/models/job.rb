# frozen_string_literal: true

class Job < ApplicationRecord
  # Multi-tenant association
  belongs_to :organization, optional: false
  belongs_to :hiring_manager, class_name: "User", optional: false
  belongs_to :department, optional: true

  # Rich text content
  has_rich_text :description
  has_rich_text :requirements
  has_rich_text :qualifications
  has_rich_text :benefits
  has_rich_text :application_instructions

  # Future associations for upcoming phases
  has_many :applications, dependent: :destroy
  has_many :candidates, through: :applications
  has_many :interviews, through: :applications
  has_many :job_templates, dependent: :destroy

  # Validations
  validates :title, presence: true, length: { minimum: 3, maximum: 200 }
  validates :description, presence: true
  validates :employment_type, inclusion: {
    in: %w[full_time part_time contract temporary internship],
    message: "must be a valid employment type"
  }
  validates :experience_level, inclusion: {
    in: %w[entry junior mid senior lead executive],
    message: "must be a valid experience level"
  }, allow_blank: true
  validates :currency, format: { with: /\A[A-Z]{3}\z/, message: "must be a valid 3-letter currency code" }
  validates :salary_range_min, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :salary_range_max, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :application_count, numericality: { greater_than_or_equal_to: 0 }
  validates :view_count, numericality: { greater_than_or_equal_to: 0 }
  validate :salary_range_consistency
  validate :expiration_date_validity
  validate :hiring_manager_belongs_to_organization

  # Scopes
  scope :published, -> { where(status: "published") }
  scope :draft, -> { where(status: "draft") }
  scope :closed, -> { where(status: "closed") }
  scope :archived, -> { where(status: "archived") }
  scope :active, -> { where(status: %w[published]) }
  scope :expired, -> { where(expires_at: ...Time.current) }
  scope :not_expired, -> { where("expires_at IS NULL OR expires_at >= ?", Time.current) }
  scope :remote_friendly, -> { where(remote_work_allowed: true) }
  scope :by_employment_type, ->(type) { where(employment_type: type) }
  scope :by_experience_level, ->(level) { where(experience_level: level) }
  scope :with_salary, -> { where.not(salary_range_min: nil) }
  scope :by_location, ->(location) { where("location ILIKE ?", "%#{location}%") }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_organization, ->(org) { where(organization: org) }

  # Enums
  enum :employment_type, {
    full_time: "full_time",
    part_time: "part_time",
    contract: "contract",
    temporary: "temporary",
    internship: "internship"
  }, validate: true

  enum :experience_level, {
    entry: "entry",
    junior: "junior",
    mid: "mid",
    senior: "senior",
    lead: "lead",
    executive: "executive"
  }, validate: { allow_blank: true }

  # State machine
  state_machine :status, initial: :draft do
    # States
    state :draft do
      validates :title, :description, :employment_type, presence: true
    end

    state :published do
      validates :title, :description, :employment_type, :hiring_manager, presence: true
    end

    state :closed
    state :archived

    # Events
    event :publish do
      transition draft: :published
    end

    event :close do
      transition published: :closed
    end

    event :reopen do
      transition closed: :published
    end

    event :archive do
      transition %i[draft published closed] => :archived
    end

    event :unarchive do
      transition archived: :draft
    end

    # Callbacks
    after_transition draft: :published do |job|
      job.update_column(:published_at, Time.current)
      job.set_default_expiration if job.expires_at.blank?
    end

    after_transition published: :closed do |job|
      # Future: Send notifications to applicants
    end

    after_transition any => :archived do |job|
      # Future: Clean up related data
    end
  end

  # Callbacks
  before_validation :normalize_fields
  before_save :update_metrics
  after_create :set_default_settings

  # Multi-tenant support
  acts_as_tenant :organization

  # Class methods
  def self.search(query)
    return none if query.blank?

    # Basic search in title and location for now
    # Rich text search will be implemented in Phase 3.3.3 with pg_search
    where(
      "title ILIKE :query OR location ILIKE :query",
      query: "%#{query}%"
    )
  end

  def self.salary_range(min_salary, max_salary)
    return all if min_salary.blank? && max_salary.blank?

    scope = all
    scope = scope.where(salary_range_max: min_salary..) if min_salary.present?
    scope = scope.where(salary_range_min: ..max_salary) if max_salary.present?
    scope
  end

  # Instance methods
  def display_title
    title.presence || "Untitled Position"
  end

  def display_location
    if remote_work_allowed? && location.present?
      "#{location} (Remote OK)"
    elsif remote_work_allowed?
      "Remote"
    else
      location.presence || "Location TBD"
    end
  end

  def salary_range_display
    return "Salary not disclosed" if salary_range_min.blank? && salary_range_max.blank?
    return "#{currency} #{formatted_salary(salary_range_min)}+" if salary_range_max.blank?
    return "Up to #{currency} #{formatted_salary(salary_range_max)}" if salary_range_min.blank?

    "#{currency} #{formatted_salary(salary_range_min)} - #{formatted_salary(salary_range_max)}"
  end

  def employment_type_display
    employment_type.humanize.titleize
  end

  def experience_level_display
    experience_level&.humanize&.titleize || "Not specified"
  end

  def can_be_published?
    title.present? && description.present? && hiring_manager.present?
  end

  def publishable_errors
    errors = []
    errors << "Title is required" if title.blank?
    errors << "Description is required" if description.blank?
    errors << "Hiring manager is required" if hiring_manager.blank?
    errors
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def days_until_expiry
    return nil if expires_at.blank?

    ((expires_at - Time.current) / 1.day).ceil
  end

  def increment_view_count!
    increment!(:view_count)
  end

  def update_application_count!
    update!(application_count: applications.count)
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

  def set_default_expiration
    self.expires_at = 30.days.from_now
    save!
  end

  private

  def salary_range_consistency
    return if salary_range_min.blank? || salary_range_max.blank?

    return unless salary_range_min > salary_range_max

    errors.add(:salary_range_max, "must be greater than or equal to minimum salary")
  end

  def expiration_date_validity
    return if expires_at.blank?

    errors.add(:expires_at, "must be in the future") if expires_at <= Time.current

    return unless published_at.present? && expires_at <= published_at

    errors.add(:expires_at, "must be after publication date")
  end

  def hiring_manager_belongs_to_organization
    return if hiring_manager.blank? || organization.blank?

    unless hiring_manager.organization_id == organization.id
      errors.add(:hiring_manager, "must belong to the same organization")
    end

    return if hiring_manager.can_manage_jobs?

    errors.add(:hiring_manager, "must have permission to manage jobs")
  end

  def normalize_fields
    self.title = title&.strip&.squeeze(" ")
    self.location = location&.strip
    self.currency = currency&.upcase if currency.present?
  end

  def update_metrics
    # This will be expanded in future phases
  end

  def set_default_settings
    return unless persisted?

    default_settings = {
      "auto_reject_after_days" => 30,
      "send_confirmation_email" => true,
      "allow_cover_letters" => true,
      "screening_questions_required" => false,
      "notify_hiring_manager" => true
    }

    self.settings = default_settings.merge(settings || {})
    save! if changed?
  end

  def formatted_salary(amount)
    return amount.to_s if amount < 1000

    if amount >= 1_000_000
      "#{(amount / 1_000_000.0).round(1)}M"
    elsif amount >= 1000
      "#{(amount / 1000.0).round(0)}K"
    else
      amount.to_s
    end
  end
end
