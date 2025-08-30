# frozen_string_literal: true

# Job model represents job postings and requisitions in the ATS system.
# Uses UUID for enhanced security and works with existing database schema.
class Job < ApplicationRecord
  # Associations
  belongs_to :company
  belongs_to :hiring_manager, class_name: 'User', optional: true

  # Application relationships
  has_many :applications, dependent: :destroy
  has_many :candidates, through: :applications
  has_many :interviews, through: :applications

  # Enums using string values to match existing schema
  enum :employment_type, {
    'full_time' => 'full_time',
    'part_time' => 'part_time', 
    'contract' => 'contract',
    'internship' => 'internship',
    'temporary' => 'temporary'
  }, prefix: true

  enum :experience_level, {
    'entry' => 'entry',
    'mid' => 'mid',
    'senior' => 'senior', 
    'executive' => 'executive'
  }, prefix: true

  enum :status, {
    'draft' => 'draft',
    'published' => 'published',
    'paused' => 'paused',
    'closed' => 'closed',
    'archived' => 'archived'
  }, prefix: true

  enum :work_location_type, {
    'on_site' => 'on_site',
    'hybrid' => 'hybrid',
    'remote' => 'remote'
  }, prefix: true

  enum :urgency, {
    'low' => 'low',
    'medium' => 'medium',
    'high' => 'high',
    'urgent' => 'urgent'
  }, prefix: true

  enum :salary_period, {
    'hourly' => 'hourly',
    'daily' => 'daily',
    'weekly' => 'weekly',
    'monthly' => 'monthly',
    'annually' => 'annually'
  }, prefix: true

  # Validations
  validates :title, presence: true, length: { minimum: 3, maximum: 100 }
  validates :company_id, presence: true
  validates :employment_type, presence: true
  validates :experience_level, presence: true
  validates :status, presence: true
  validates :work_location_type, presence: true

  # Salary validations
  validates :salary_min, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :salary_max, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :salary_currency, presence: true, length: { is: 3 }, if: -> { salary_min.present? || salary_max.present? }
  validate :salary_max_greater_than_min

  # Date validations
  validates :posted_at, presence: true, if: :is_published?
  validates :application_deadline, comparison: { greater_than: :posted_at }, allow_nil: true, if: :posted_at?
  validates :target_start_date, comparison: { greater_than: :posted_at }, allow_nil: true, if: :posted_at?

  # Other validations
  validates :location, length: { maximum: 100 }, allow_blank: true
  validates :openings_count, numericality: { greater_than: 0 }, allow_nil: true
  validates :referral_bonus_amount, length: { maximum: 50 }, allow_blank: true

  # Scopes for filtering and search
  scope :active, -> { where(active: true, deleted_at: nil) }
  scope :published, -> { where(status: 'published') }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_employment_type, ->(type) { where(employment_type: type) }
  scope :by_experience_level, ->(level) { where(experience_level: level) }
  scope :by_work_location_type, ->(type) { where(work_location_type: type) }
  scope :by_department, ->(dept_id) { where(department_id: dept_id) }
  scope :by_location, ->(loc) { where('location ILIKE ?', "%#{loc}%") }
  scope :by_urgency, ->(urgency) { where(urgency: urgency) }
  scope :with_salary_range, ->(min, max) { where('salary_min >= ? AND salary_max <= ?', min, max) }
  scope :posted_within, ->(period) { where('posted_at >= ?', period.ago) }
  scope :recent, -> { order(posted_at: :desc) }
  scope :by_company, ->(org_id) { where(company_id: org_id) }
  scope :by_hiring_manager, ->(manager_id) { where(hiring_manager_id: manager_id) }
  scope :confidential, -> { where(confidential: true) }
  scope :public_jobs, -> { where(confidential: false) }
  scope :remote_eligible, -> { where(remote_work_eligible: true) }
  scope :with_openings, -> { where('openings_count > 0') }
  scope :application_open, -> { where('application_deadline > ? OR application_deadline IS NULL', Time.current) }

  # Search scopes
  scope :search_by_title, ->(query) { where('title ILIKE ?', "%#{query}%") }
  scope :search_by_content, ->(query) do
    where('title ILIKE :query OR description ILIKE :query OR requirements ILIKE :query', query: "%#{query}%")
  end
  scope :with_required_skills, ->(skills) do
    skills_array = Array(skills)
    where("required_skills ?| array[:skills]", skills: skills_array)
  end
  scope :with_nice_to_have_skills, ->(skills) do
    skills_array = Array(skills)
    where("nice_to_have_skills ?| array[:skills]", skills: skills_array)
  end

  # Callbacks
  before_validation :set_posted_at_on_publish
  before_validation :normalize_currency
  before_validation :set_defaults
  after_update :update_active_status

  # Helper methods for formatted display
  def formatted_salary_range
    return 'Salary not specified' if salary_min.blank? && salary_max.blank?
    
    min_formatted = format_salary(salary_min) if salary_min.present?
    max_formatted = format_salary(salary_max) if salary_max.present?
    
    case
    when salary_min.present? && salary_max.present?
      "#{min_formatted} - #{max_formatted} #{salary_period_display}"
    when salary_min.present?
      "From #{min_formatted} #{salary_period_display}"
    when salary_max.present?
      "Up to #{max_formatted} #{salary_period_display}"
    end
  end

  def salary_period_display
    return '' if salary_period.blank?
    
    case salary_period
    when 'hourly' then 'per hour'
    when 'daily' then 'per day'
    when 'weekly' then 'per week'
    when 'monthly' then 'per month'
    when 'annually' then 'per year'
    else salary_period
    end
  end

  def employment_type_humanized
    employment_type&.humanize
  end

  def experience_level_humanized
    case experience_level
    when 'entry' then 'Entry Level'
    when 'mid' then 'Mid Level' 
    when 'senior' then 'Senior Level'
    when 'executive' then 'Executive Level'
    else experience_level&.humanize
    end
  end

  def work_location_type_humanized
    case work_location_type
    when 'on_site' then 'On-site'
    when 'hybrid' then 'Hybrid'
    when 'remote' then 'Remote'
    else work_location_type&.humanize
    end
  end

  def status_humanized
    status&.humanize
  end

  def urgency_humanized
    urgency&.humanize
  end

  def days_since_posted
    return nil unless posted_at
    
    (Date.current - posted_at.to_date).to_i
  end

  def days_until_deadline
    return nil unless application_deadline
    
    (application_deadline.to_date - Date.current).to_i
  end

  def is_active?
    active? && deleted_at.nil?
  end

  def is_published?
    status == 'published'
  end

  def can_be_published?
    status == 'draft' && title.present? && description.present?
  end

  def can_be_closed?
    %w[published paused].include?(status)
  end

  def is_confidential?
    confidential?
  end

  def allows_remote_work?
    remote_work_eligible? || work_location_type == 'remote'
  end

  def has_openings?
    openings_count.present? && openings_count > 0
  end

  def applications_open?
    application_deadline.nil? || application_deadline > Time.current
  end

  def required_skills_list
    required_skills.is_a?(Array) ? required_skills : []
  end

  def nice_to_have_skills_list
    nice_to_have_skills.is_a?(Array) ? nice_to_have_skills : []
  end

  def all_skills
    (required_skills_list + nice_to_have_skills_list).uniq
  end

  def pipeline_stages_list
    pipeline_stages.is_a?(Array) ? pipeline_stages : []
  end

  # State transition methods
  def publish!
    return false unless can_be_published?
    
    update!(status: 'published', posted_at: Time.current, active: true)
  end

  def pause!
    return false unless is_published?
    
    update!(status: 'paused')
  end

  def close!
    return false unless can_be_closed?
    
    update!(status: 'closed', active: false)
  end

  def archive!
    update!(status: 'archived', active: false)
  end

  def soft_delete!
    update!(deleted_at: Time.current, active: false)
  end

  def restore!
    update!(deleted_at: nil, active: true) if deleted_at.present?
  end

  # Class methods
  def self.search(query)
    return all if query.blank?
    
    search_by_content(query)
  end

  private

  def format_salary(amount)
    return '' if amount.blank?
    
    # Handle both decimal and integer amounts
    amount_formatted = amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    
    case salary_currency&.upcase
    when 'USD', 'CAD', 'AUD'
      "$#{amount_formatted}"
    when 'EUR'
      "€#{amount_formatted}"
    when 'GBP'
      "£#{amount_formatted}"
    else
      "#{amount_formatted} #{salary_currency}"
    end
  end

  def salary_max_greater_than_min
    return unless salary_min.present? && salary_max.present?
    
    errors.add(:salary_max, 'must be greater than minimum salary') if salary_max <= salary_min
  end

  def set_posted_at_on_publish
    if status_changed? && status == 'published' && posted_at.blank?
      self.posted_at = Time.current
    end
  end

  def normalize_currency
    self.salary_currency = salary_currency&.upcase
  end

  def set_defaults
    self.active = true if active.nil?
    self.confidential = false if confidential.nil?
    self.remote_work_eligible = false if remote_work_eligible.nil?
    self.openings_count = 1 if openings_count.blank?
    self.required_skills = [] if required_skills.blank?
    self.nice_to_have_skills = [] if nice_to_have_skills.blank?
    self.pipeline_stages = [] if pipeline_stages.blank?
  end

  def update_active_status
    if saved_change_to_status?
      case status
      when 'published'
        self.update_column(:active, true) unless active?
      when 'closed', 'archived'
        self.update_column(:active, false) if active?
      end
    end
  end
end