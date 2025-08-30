# frozen_string_literal: true

# == Schema Information
#
# Table name: interviews
#
#  id               :uuid             not null, primary key
#  application_id   :uuid             not null
#  interviewer_id   :uuid             not null
#  scheduled_by_id  :uuid
#  interview_type   :string           not null
#  status           :string           default("scheduled"), not null
#  scheduled_at     :datetime         not null
#  duration_minutes :integer          default(60)
#  location         :string(255)
#  video_link       :string(500)
#  calendar_event_id:string(100)
#  feedback         :text
#  rating           :integer
#  decision         :string
#  completed_at     :datetime
#  notes            :text
#  metadata         :jsonb            not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_interviews_on_application_and_status         (application_id,status)
#  index_interviews_on_application_and_scheduled_at   (application_id,scheduled_at)
#  index_interviews_on_interviewer_and_status         (interviewer_id,status)
#  index_interviews_on_interviewer_and_scheduled_at   (interviewer_id,scheduled_at)
#  (and other individual column indexes)
#
# Foreign Keys
#
#  fk_rails_...  (application_id => applications.id)
#  fk_rails_...  (interviewer_id => users.id)
#  fk_rails_...  (scheduled_by_id => users.id)
#

class Interview < ApplicationRecord
  # Associations
  belongs_to :application
  belongs_to :interviewer, class_name: 'User'
  belongs_to :scheduled_by, class_name: 'User', optional: true
  
  # Delegated associations
  has_one :candidate, through: :application
  has_one :job, through: :application
  has_one :company, through: :application

  # Enums using string values to match database schema
  enum :interview_type, {
    'phone' => 'phone',
    'video' => 'video',
    'onsite' => 'onsite',
    'technical' => 'technical',
    'behavioral' => 'behavioral',
    'panel' => 'panel'
  }, prefix: true

  enum :status, {
    'scheduled' => 'scheduled',
    'confirmed' => 'confirmed',
    'completed' => 'completed',
    'cancelled' => 'cancelled',
    'no_show' => 'no_show'
  }, prefix: true

  enum :decision, {
    'strong_yes' => 'strong_yes',
    'yes' => 'yes',
    'maybe' => 'maybe',
    'no' => 'no',
    'strong_no' => 'strong_no'
  }, prefix: true, allow_nil: true

  # Validations
  validates :application_id, presence: true
  validates :interviewer_id, presence: true
  validates :interview_type, presence: true
  validates :status, presence: true
  validates :scheduled_at, presence: true
  validates :duration_minutes, presence: true, numericality: { 
    greater_than: 0,
    less_than_or_equal_to: 480, # 8 hours max
    message: 'must be between 1 and 480 minutes' 
  }
  validates :metadata, presence: true

  # Rating validation
  validates :rating, inclusion: { 
    in: 1..5, 
    message: 'must be between 1 and 5' 
  }, allow_nil: true

  # String length validations
  validates :location, length: { maximum: 255 }
  validates :video_link, length: { maximum: 500 }
  validates :calendar_event_id, length: { maximum: 100 }
  validates :feedback, length: { maximum: 2000 }
  validates :notes, length: { maximum: 1000 }

  # URL format validation for video links
  validates :video_link, format: { 
    with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
    message: 'must be a valid URL' 
  }, allow_blank: true

  # Custom validations
  validate :completion_data_consistency
  validate :interviewer_belongs_to_company
  validate :scheduled_by_belongs_to_company
  validate :location_required_for_onsite
  validate :video_link_required_for_video_calls
  validate :scheduled_at_not_in_past, on: :create
  validate :decision_requires_completion

  # Callbacks
  before_validation :set_default_duration, on: :create
  before_validation :normalize_video_link
  after_update :update_completion_timestamp, if: :saved_change_to_status?
  after_create :update_application_status_if_needed
  after_update :update_application_status_if_needed, if: :saved_change_to_status?

  # Scopes
  scope :for_application, ->(application) { where(application: application) }
  scope :for_interviewer, ->(interviewer) { where(interviewer: interviewer) }
  scope :for_company, ->(company) { joins(:application).where(applications: { company: company }) }
  scope :by_type, ->(type) { where(interview_type: type) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_decision, ->(decision) { where(decision: decision) }
  scope :with_rating, ->(rating) { where(rating: rating) }
  
  # Timeline scopes
  scope :scheduled_between, ->(start_time, end_time) { where(scheduled_at: start_time..end_time) }
  scope :scheduled_for_date, ->(date) { where(scheduled_at: date.beginning_of_day..date.end_of_day) }
  scope :scheduled_today, -> { scheduled_for_date(Date.current) }
  scope :scheduled_tomorrow, -> { scheduled_for_date(Date.current + 1.day) }
  scope :scheduled_this_week, -> { scheduled_between(Date.current.beginning_of_week, Date.current.end_of_week) }
  scope :upcoming, -> { where('scheduled_at > ?', Time.current).order(:scheduled_at) }
  scope :past, -> { where('scheduled_at <= ?', Time.current).order(scheduled_at: :desc) }
  scope :recent, -> { order(scheduled_at: :desc) }
  
  # Status-based scopes
  scope :active, -> { where(status: ['scheduled', 'confirmed']) }
  scope :completed, -> { where(status: 'completed') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :no_shows, -> { where(status: 'no_show') }
  scope :needs_feedback, -> { completed.where(feedback: [nil, '']) }
  scope :with_feedback, -> { completed.where.not(feedback: [nil, '']) }
  
  # Decision and rating scopes
  scope :positive_decisions, -> { where(decision: ['strong_yes', 'yes']) }
  scope :negative_decisions, -> { where(decision: ['strong_no', 'no']) }
  scope :neutral_decisions, -> { where(decision: 'maybe') }
  scope :highly_rated, -> { where('rating >= ?', 4) }
  scope :poorly_rated, -> { where('rating <= ?', 2) }
  scope :rated, -> { where.not(rating: nil) }
  scope :unrated, -> { where(rating: nil) }
  
  # Duration and type scopes
  scope :short_interviews, -> { where('duration_minutes <= ?', 30) }
  scope :long_interviews, -> { where('duration_minutes >= ?', 120) }
  scope :remote_interviews, -> { where(interview_type: ['phone', 'video']) }
  scope :in_person_interviews, -> { where(interview_type: 'onsite') }
  scope :technical_interviews, -> { where(interview_type: 'technical') }
  
  # Search scopes
  scope :search_in_feedback, ->(query) { 
    where('feedback ILIKE ? OR notes ILIKE ?', "%#{query}%", "%#{query}%") 
  }
  scope :with_calendar_event, -> { where.not(calendar_event_id: [nil, '']) }

  # Delegations
  delegate :full_name, :email, to: :candidate, prefix: true
  delegate :title, to: :job, prefix: true
  delegate :name, to: :company, prefix: true
  delegate :full_name, :email, to: :interviewer, prefix: true
  delegate :full_name, to: :scheduled_by, prefix: true, allow_nil: true

  # State transition methods
  def confirm!
    return false unless can_be_confirmed?
    
    update!(status: 'confirmed')
  end

  def complete!(feedback: nil, rating: nil, decision: nil, notes: nil)
    return false unless can_be_completed?
    
    attributes_to_update = { 
      status: 'completed',
      completed_at: Time.current
    }
    
    attributes_to_update[:feedback] = feedback if feedback.present?
    attributes_to_update[:rating] = rating if rating.present?
    attributes_to_update[:decision] = decision if decision.present?
    attributes_to_update[:notes] = notes if notes.present?
    
    update!(attributes_to_update)
  end

  def cancel!(reason: nil)
    return false unless can_be_cancelled?
    
    attributes_to_update = { status: 'cancelled' }
    attributes_to_update[:notes] = [self.notes, "Cancelled: #{reason}"].compact.join("\n\n") if reason.present?
    
    update!(attributes_to_update)
  end

  def mark_no_show!(notes: nil)
    return false unless can_be_marked_no_show?
    
    attributes_to_update = { status: 'no_show' }
    attributes_to_update[:notes] = [self.notes, notes].compact.join("\n\n") if notes.present?
    
    update!(attributes_to_update)
  end

  def reschedule!(new_time:, changed_by: nil, reason: nil)
    return false unless can_be_rescheduled?
    
    attributes_to_update = { 
      scheduled_at: new_time,
      scheduled_by: changed_by || scheduled_by,
      status: 'scheduled'
    }
    
    if reason.present?
      attributes_to_update[:notes] = [self.notes, "Rescheduled: #{reason}"].compact.join("\n\n") 
    end
    
    update!(attributes_to_update)
  end

  # Query methods
  def can_be_confirmed?
    status_scheduled?
  end

  def can_be_completed?
    %w[scheduled confirmed].include?(status) && scheduled_at <= Time.current
  end

  def can_be_cancelled?
    %w[scheduled confirmed].include?(status)
  end

  def can_be_marked_no_show?
    %w[scheduled confirmed].include?(status) && scheduled_at <= Time.current
  end

  def can_be_rescheduled?
    %w[scheduled confirmed].include?(status)
  end

  def is_upcoming?
    scheduled_at > Time.current && %w[scheduled confirmed].include?(status)
  end

  def is_today?
    scheduled_at.to_date == Date.current
  end

  def is_overdue?
    scheduled_at <= Time.current && %w[scheduled confirmed].include?(status)
  end

  def requires_location?
    interview_type_onsite?
  end

  def requires_video_link?
    interview_type_video?
  end

  def is_remote?
    %w[phone video].include?(interview_type)
  end

  def has_positive_decision?
    %w[strong_yes yes].include?(decision)
  end

  def has_negative_decision?
    %w[strong_no no].include?(decision)
  end

  def has_feedback?
    feedback.present? && feedback.strip.present?
  end

  def needs_feedback?
    status_completed? && !has_feedback?
  end

  # Time-based methods
  def time_until_interview
    return 0 if scheduled_at <= Time.current
    
    ((scheduled_at - Time.current) / 1.hour).round(1)
  end

  def days_until_interview
    return 0 if scheduled_at <= Time.current
    
    (scheduled_at.to_date - Date.current).to_i
  end

  def duration_in_hours
    (duration_minutes / 60.0).round(1)
  end

  def scheduled_time_range
    return nil unless scheduled_at && duration_minutes
    
    end_time = scheduled_at + duration_minutes.minutes
    "#{scheduled_at.strftime('%I:%M %p')} - #{end_time.strftime('%I:%M %p')}"
  end

  # Formatting methods
  def interview_type_humanized
    case interview_type
    when 'phone' then 'Phone Interview'
    when 'video' then 'Video Interview'
    when 'onsite' then 'On-site Interview'
    when 'technical' then 'Technical Interview'
    when 'behavioral' then 'Behavioral Interview'
    when 'panel' then 'Panel Interview'
    else
      interview_type.humanize
    end
  end

  def status_humanized
    case status
    when 'no_show' then 'No Show'
    else
      status.humanize
    end
  end

  def decision_humanized
    return 'No decision yet' if decision.blank?
    
    case decision
    when 'strong_yes' then 'Strong Yes ⭐⭐'
    when 'yes' then 'Yes ⭐'
    when 'maybe' then 'Maybe ❓'
    when 'no' then 'No ❌'
    when 'strong_no' then 'Strong No ❌❌'
    else
      decision.humanize
    end
  end

  def rating_display
    return 'Not rated' unless rating.present?
    
    "#{rating}/5 #{'★' * rating}#{'☆' * (5 - rating)}"
  end

  def duration_display
    case duration_minutes
    when 0..59
      "#{duration_minutes} min"
    when 60
      "1 hour"
    else
      hours = duration_minutes / 60
      minutes = duration_minutes % 60
      minutes > 0 ? "#{hours}h #{minutes}m" : "#{hours} hour#{'s' if hours > 1}"
    end
  end

  def formatted_scheduled_time
    scheduled_at.strftime('%A, %B %d, %Y at %I:%M %p')
  end

  def short_scheduled_time
    if scheduled_at.to_date == Date.current
      "Today at #{scheduled_at.strftime('%I:%M %p')}"
    elsif scheduled_at.to_date == Date.current + 1.day
      "Tomorrow at #{scheduled_at.strftime('%I:%M %p')}"
    else
      scheduled_at.strftime('%m/%d/%Y %I:%M %p')
    end
  end

  # Metadata helpers
  def set_metadata(key, value)
    self.metadata = metadata.merge(key.to_s => value)
    save!
  end

  def get_metadata(key)
    metadata[key.to_s]
  end

  # Class methods
  def self.completion_rate
    total = count
    return 0 if total.zero?
    
    completed_count = completed.count
    ((completed_count.to_f / total) * 100).round(1)
  end

  def self.average_rating
    ratings = completed.where.not(rating: nil).pluck(:rating)
    return 0 if ratings.empty?
    
    (ratings.sum.to_f / ratings.count).round(1)
  end

  def self.no_show_rate
    total = where.not(status: 'cancelled').count
    return 0 if total.zero?
    
    no_show_count = no_shows.count
    ((no_show_count.to_f / total) * 100).round(1)
  end

  def self.decision_breakdown
    completed.where.not(decision: nil).group(:decision).count
  end

  def self.type_breakdown
    group(:interview_type).count
  end

  def self.average_duration
    avg_minutes = average(:duration_minutes)
    return 0 if avg_minutes.nil?
    
    avg_minutes.round
  end

  private

  def set_default_duration
    return if duration_minutes.present?
    
    self.duration_minutes = case interview_type
                           when 'phone' then 30
                           when 'video' then 45
                           when 'technical' then 90
                           when 'panel' then 90
                           when 'behavioral' then 60
                           when 'onsite' then 60
                           else 60
                           end
  end

  def normalize_video_link
    return unless video_link.present?
    
    self.video_link = video_link.strip
    # Add https:// if no protocol specified
    unless video_link.match?(/\Ahttps?:\/\//)
      self.video_link = "https://#{video_link}"
    end
  end

  def update_completion_timestamp
    if status == 'completed' && completed_at.blank?
      update_column(:completed_at, Time.current)
    elsif status != 'completed' && completed_at.present?
      update_column(:completed_at, nil)
    end
  end

  def update_application_status_if_needed
    # This could be enhanced to automatically advance application status
    # based on interview outcomes and business rules
    return unless status_completed? && has_positive_decision?
    
    # Example: Auto-advance to next stage if interview was positive
    # This would be customizable per company's workflow
  end

  def completion_data_consistency
    if status == 'completed'
      errors.add(:completed_at, 'must be present when status is completed') if completed_at.blank?
    elsif completed_at.present?
      errors.add(:completed_at, 'must be blank when status is not completed')
    end
  end

  def interviewer_belongs_to_company
    return unless interviewer.present? && application&.company.present?
    
    unless interviewer.company_id == application.company_id
      errors.add(:interviewer, 'must belong to the same company as the application')
    end
  end

  def scheduled_by_belongs_to_company
    return unless scheduled_by.present? && application&.company.present?
    
    unless scheduled_by.company_id == application.company_id
      errors.add(:scheduled_by, 'must belong to the same company as the application')
    end
  end

  def location_required_for_onsite
    if interview_type_onsite? && location.blank?
      errors.add(:location, 'is required for onsite interviews')
    end
  end

  def video_link_required_for_video_calls
    if interview_type_video? && video_link.blank?
      errors.add(:video_link, 'is required for video interviews')
    end
  end

  def scheduled_at_not_in_past
    return unless scheduled_at.present?
    
    if scheduled_at <= Time.current
      errors.add(:scheduled_at, 'must be in the future')
    end
  end

  def decision_requires_completion
    return unless decision.present?
    
    unless status_completed?
      errors.add(:decision, 'can only be set when interview is completed')
    end
  end
end