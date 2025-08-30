# frozen_string_literal: true

# == Schema Information
#
# Table name: applications
#
#  id                  :uuid             not null, primary key
#  company_id          :uuid             not null
#  job_id              :uuid             not null
#  candidate_id        :uuid             not null
#  stage_changed_by_id :uuid
#  status              :string           default("applied"), not null
#  source              :string(100)
#  applied_at          :datetime         not null
#  stage_changed_at    :datetime
#  rejected_at         :datetime
#  cover_letter        :text
#  notes               :text
#  rating              :integer
#  rejection_reason    :string(255)
#  salary_offered      :integer
#  metadata            :jsonb            not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_applications_on_candidate_and_job_unique    (candidate_id,job_id) UNIQUE
#  index_applications_on_candidate_and_status        (candidate_id,status)
#  index_applications_on_company_and_applied_at      (company_id,applied_at)
#  index_applications_on_company_and_status          (company_id,status)
#  index_applications_on_job_and_applied_at          (job_id,applied_at)
#  index_applications_on_job_and_status              (job_id,status)
#  (and other individual column indexes)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (job_id => jobs.id)
#  fk_rails_...  (candidate_id => candidates.id)
#  fk_rails_...  (stage_changed_by_id => users.id)
#

class Application < ApplicationRecord
  # Associations
  belongs_to :company
  belongs_to :job
  belongs_to :candidate
  belongs_to :stage_changed_by, class_name: 'User', optional: true
  
  has_many :interviews, dependent: :destroy

  # Enums using string values to match database schema
  enum :status, {
    'applied' => 'applied',
    'screening' => 'screening', 
    'phone_interview' => 'phone_interview',
    'technical_interview' => 'technical_interview',
    'final_interview' => 'final_interview',
    'offer' => 'offer',
    'accepted' => 'accepted',
    'rejected' => 'rejected',
    'withdrawn' => 'withdrawn'
  }, prefix: true

  # Common application sources
  APPLICATION_SOURCES = [
    'website', 'linkedin', 'indeed', 'glassdoor', 'referral', 
    'recruiter', 'career_fair', 'university', 'direct', 'other'
  ].freeze

  # Validations
  validates :company_id, presence: true
  validates :job_id, presence: true
  validates :candidate_id, presence: true
  validates :status, presence: true
  validates :applied_at, presence: true
  validates :metadata, presence: true

  # Unique constraint validation (also enforced at DB level)
  validates :candidate_id, uniqueness: { 
    scope: :job_id, 
    message: 'has already applied to this job' 
  }

  # Rating validation
  validates :rating, inclusion: { 
    in: 1..5, 
    message: 'must be between 1 and 5' 
  }, allow_nil: true

  # Salary validation
  validates :salary_offered, numericality: { 
    greater_than_or_equal_to: 0,
    message: 'must be a positive amount'
  }, allow_nil: true

  # Source validation
  validates :source, inclusion: { 
    in: APPLICATION_SOURCES, 
    message: 'is not a valid application source' 
  }, allow_blank: true

  # String length validations
  validates :rejection_reason, length: { maximum: 255 }
  validates :source, length: { maximum: 100 }
  validates :cover_letter, length: { maximum: 5000 }
  validates :notes, length: { maximum: 2000 }

  # Custom validations
  validate :rejection_data_consistency
  validate :stage_changed_by_belongs_to_company
  validate :applied_at_not_in_future

  # Callbacks
  before_validation :set_applied_at, on: :create
  before_validation :set_stage_changed_at, if: :status_changed?
  after_update :update_rejection_timestamp, if: :saved_change_to_status?

  # Scopes
  scope :for_company, ->(company) { where(company: company) }
  scope :for_job, ->(job) { where(job: job) }
  scope :for_candidate, ->(candidate) { where(candidate: candidate) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_source, ->(source) { where(source: source) }
  scope :with_rating, ->(rating) { where(rating: rating) }
  scope :rated_applications, -> { where.not(rating: nil) }
  scope :unrated_applications, -> { where(rating: nil) }
  
  # Timeline scopes
  scope :applied_between, ->(start_date, end_date) { where(applied_at: start_date..end_date) }
  scope :applied_since, ->(date) { where('applied_at >= ?', date) }
  scope :recent, -> { order(applied_at: :desc) }
  scope :oldest_first, -> { order(applied_at: :asc) }
  scope :by_stage_change, -> { order(stage_changed_at: :desc) }
  
  # Status-based scopes
  scope :active, -> { where.not(status: ['rejected', 'withdrawn', 'accepted']) }
  scope :closed, -> { where(status: ['rejected', 'withdrawn', 'accepted']) }
  scope :in_pipeline, -> { where(status: ['screening', 'phone_interview', 'technical_interview', 'final_interview']) }
  scope :needs_action, -> { where(status: ['applied', 'screening']) }
  scope :interview_stage, -> { where(status: ['phone_interview', 'technical_interview', 'final_interview']) }
  scope :offer_stage, -> { where(status: ['offer', 'accepted']) }
  scope :rejected, -> { where(status: 'rejected') }
  scope :withdrawn, -> { where(status: 'withdrawn') }
  
  # Rating and feedback scopes
  scope :highly_rated, -> { where('rating >= ?', 4) }
  scope :poorly_rated, -> { where('rating <= ?', 2) }
  scope :with_offer, -> { where.not(salary_offered: nil) }
  scope :with_notes, -> { where.not(notes: [nil, '']) }
  scope :with_cover_letter, -> { where.not(cover_letter: [nil, '']) }

  # Search scopes
  scope :search_by_rejection_reason, ->(query) { 
    where('rejection_reason ILIKE ?', "%#{query}%") 
  }
  
  scope :search_in_notes, ->(query) { 
    where('notes ILIKE ? OR cover_letter ILIKE ?', "%#{query}%", "%#{query}%") 
  }

  # Delegations
  delegate :full_name, :email, :phone, to: :candidate, prefix: true
  delegate :title, :employment_type, to: :job, prefix: true
  delegate :name, to: :company, prefix: true
  delegate :full_name, to: :stage_changed_by, prefix: true, allow_nil: true

  # State transition methods
  def advance_to_screening!(changed_by: nil, notes: nil)
    transition_to_status!('screening', changed_by: changed_by, notes: notes)
  end

  def advance_to_phone_interview!(changed_by: nil, notes: nil)
    transition_to_status!('phone_interview', changed_by: changed_by, notes: notes)
  end

  def advance_to_technical_interview!(changed_by: nil, notes: nil)
    transition_to_status!('technical_interview', changed_by: changed_by, notes: notes)
  end

  def advance_to_final_interview!(changed_by: nil, notes: nil)
    transition_to_status!('final_interview', changed_by: changed_by, notes: notes)
  end

  def extend_offer!(salary_amount: nil, changed_by: nil, notes: nil)
    attributes_to_update = { 
      status: 'offer',
      stage_changed_by: changed_by,
      stage_changed_at: Time.current
    }
    
    attributes_to_update[:salary_offered] = salary_amount if salary_amount.present?
    attributes_to_update[:notes] = [self.notes, notes].compact.join("\n\n") if notes.present?
    
    update!(attributes_to_update)
  end

  def accept_offer!(changed_by: nil, notes: nil)
    transition_to_status!('accepted', changed_by: changed_by, notes: notes)
  end

  def reject!(reason: nil, changed_by: nil, notes: nil)
    attributes_to_update = { 
      status: 'rejected',
      rejected_at: Time.current,
      stage_changed_by: changed_by,
      stage_changed_at: Time.current
    }
    
    attributes_to_update[:rejection_reason] = reason if reason.present?
    attributes_to_update[:notes] = [self.notes, notes].compact.join("\n\n") if notes.present?
    
    update!(attributes_to_update)
  end

  def withdraw!(reason: nil, changed_by: nil, notes: nil)
    attributes_to_update = { 
      status: 'withdrawn',
      stage_changed_by: changed_by,
      stage_changed_at: Time.current
    }
    
    attributes_to_update[:rejection_reason] = reason if reason.present?
    attributes_to_update[:notes] = [self.notes, notes].compact.join("\n\n") if notes.present?
    
    update!(attributes_to_update)
  end

  # Query methods
  def active?
    !%w[rejected withdrawn accepted].include?(status)
  end

  def closed?
    %w[rejected withdrawn accepted].include?(status)
  end

  def in_interview_stage?
    %w[phone_interview technical_interview final_interview].include?(status)
  end

  def needs_action?
    %w[applied screening].include?(status)
  end

  def has_offer?
    salary_offered.present?
  end

  def rated?
    rating.present?
  end

  def highly_rated?
    rating.present? && rating >= 4
  end

  def rejected?
    status == 'rejected'
  end

  def accepted?
    status == 'accepted'
  end

  def withdrawn?
    status == 'withdrawn'
  end

  # Time-based methods
  def days_since_applied
    return 0 unless applied_at
    
    (Date.current - applied_at.to_date).to_i
  end

  def days_in_current_stage
    return 0 unless stage_changed_at || applied_at
    
    reference_time = stage_changed_at || applied_at
    (Date.current - reference_time.to_date).to_i
  end

  def time_to_hire
    return nil unless accepted? && applied_at
    
    (updated_at.to_date - applied_at.to_date).to_i
  end

  # Formatting methods
  def status_humanized
    case status
    when 'phone_interview' then 'Phone Interview'
    when 'technical_interview' then 'Technical Interview'
    when 'final_interview' then 'Final Interview'
    else
      status.humanize
    end
  end

  def formatted_salary_offered
    return 'No offer made' unless salary_offered.present?
    
    # Convert cents to dollars and format
    amount = salary_offered / 100.0
    "$#{number_with_delimiter(amount.to_i)}"
  end

  def source_humanized
    return 'Not specified' if source.blank?
    
    case source
    when 'career_fair' then 'Career Fair'
    else
      source.humanize
    end
  end

  def rating_display
    return 'Not rated' unless rating.present?
    
    "#{rating}/5 #{'★' * rating}#{'☆' * (5 - rating)}"
  end

  # Metadata helpers
  def set_metadata(key, value)
    self.metadata = metadata.merge(key.to_s => value)
    save!
  end

  def get_metadata(key)
    metadata[key.to_s]
  end

  # Interview management
  def upcoming_interviews
    interviews.where('scheduled_at > ?', Time.current).order(:scheduled_at)
  end

  def past_interviews
    interviews.where('scheduled_at <= ?', Time.current).order(scheduled_at: :desc)
  end

  def completed_interviews
    interviews.where(status: 'completed')
  end

  def average_interview_rating
    ratings = completed_interviews.where.not(rating: nil).pluck(:rating)
    return nil if ratings.empty?
    
    (ratings.sum.to_f / ratings.count).round(1)
  end

  # Class methods
  def self.by_pipeline_stage
    group(:status).count
  end

  def self.conversion_rate(from_status, to_status)
    from_count = where(status: from_status).count
    return 0 if from_count.zero?
    
    to_count = where(status: to_status).count
    ((to_count.to_f / from_count) * 100).round(1)
  end

  def self.average_time_to_hire
    accepted_apps = where(status: 'accepted').where.not(applied_at: nil)
    return 0 if accepted_apps.empty?
    
    total_days = accepted_apps.sum { |app| app.time_to_hire || 0 }
    (total_days.to_f / accepted_apps.count).round(1)
  end

  def self.source_breakdown
    where.not(source: nil).group(:source).count
  end

  private

  def number_with_delimiter(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

  def transition_to_status!(new_status, changed_by: nil, notes: nil)
    attributes_to_update = { 
      status: new_status,
      stage_changed_by: changed_by,
      stage_changed_at: Time.current
    }
    
    attributes_to_update[:notes] = [self.notes, notes].compact.join("\n\n") if notes.present?
    
    update!(attributes_to_update)
  end

  def set_applied_at
    self.applied_at ||= Time.current
  end

  def set_stage_changed_at
    self.stage_changed_at = Time.current if status_changed?
  end

  def update_rejection_timestamp
    if status == 'rejected' && rejected_at.blank?
      update_column(:rejected_at, Time.current)
    elsif status != 'rejected' && rejected_at.present?
      update_column(:rejected_at, nil)
    end
  end

  def rejection_data_consistency
    if status == 'rejected'
      errors.add(:rejected_at, 'must be present when status is rejected') if rejected_at.blank?
    elsif rejected_at.present?
      errors.add(:rejected_at, 'must be blank when status is not rejected') 
    end
  end

  def stage_changed_by_belongs_to_company
    return unless stage_changed_by.present? && company.present?
    
    unless stage_changed_by.company_id == company_id
      errors.add(:stage_changed_by, 'must belong to the same company')
    end
  end

  def applied_at_not_in_future
    return unless applied_at.present?
    
    if applied_at > Time.current
      errors.add(:applied_at, 'cannot be in the future')
    end
  end
end