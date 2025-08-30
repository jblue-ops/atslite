# frozen_string_literal: true

# Candidate model represents job applicant profiles in the ATS system.
# Uses UUID for enhanced security and works with existing database schema.
class Candidate < ApplicationRecord
  # Application relationships
  has_many :applications, dependent: :destroy
  has_many :jobs, through: :applications
  has_many :interviews, through: :applications
  
  # Future associations (to be implemented)
  # has_many :notes, as: :noteable, dependent: :destroy

  # Enums using string values to match existing schema
  enum :work_authorization, {
    'citizen' => 'citizen',
    'permanent_resident' => 'permanent_resident',
    'work_visa' => 'work_visa',
    'student_visa' => 'student_visa',
    'needs_sponsorship' => 'needs_sponsorship'
  }, prefix: true

  enum :notice_period, {
    'immediate' => 'immediate',
    'two_weeks' => 'two_weeks',
    'one_month' => 'one_month',
    'two_months' => 'two_months',
    'three_months' => 'three_months',
    'other' => 'other'
  }, prefix: true

  # Validations
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: true
  validates :first_name, presence: true, length: { minimum: 1, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 1, maximum: 100 }

  # Optional field validations
  validates :phone, format: { 
    with: /\A[\+\d\s\-\(\)\.]+\z/, 
    message: 'must be a valid phone number' 
  }, allow_blank: true

  validates :linkedin_url, format: { 
    with: /\Ahttps?:\/\/(www\.)?linkedin\.com\/in\/[\w\-]+\/?/i,
    message: 'must be a valid LinkedIn profile URL' 
  }, allow_blank: true

  validates :portfolio_url, format: { 
    with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
    message: 'must be a valid URL' 
  }, allow_blank: true

  validates :github_url, format: { 
    with: /\Ahttps?:\/\/(www\.)?github\.com\/[\w\-]+\/?/i,
    message: 'must be a valid GitHub profile URL' 
  }, allow_blank: true

  validates :years_of_experience, numericality: { 
    greater_than_or_equal_to: 0, 
    less_than: 70 
  }, allow_blank: true

  validates :current_salary, numericality: { 
    greater_than_or_equal_to: 0 
  }, allow_blank: true

  validates :desired_salary_min, numericality: { 
    greater_than_or_equal_to: 0 
  }, allow_blank: true

  validates :desired_salary_max, numericality: { 
    greater_than_or_equal_to: 0 
  }, allow_blank: true

  validate :desired_salary_max_greater_than_min

  validates :location, length: { maximum: 100 }, allow_blank: true
  validates :bio, length: { maximum: 2000 }, allow_blank: true
  validates :current_job_title, length: { maximum: 100 }, allow_blank: true
  validates :current_company, length: { maximum: 100 }, allow_blank: true

  # Scopes for filtering and search
  scope :by_work_authorization, ->(status) { where(work_authorization: status) }
  scope :by_notice_period, ->(period) { where(notice_period: period) }
  scope :by_location, ->(location) { where('location ILIKE ?', "%#{location}%") }
  scope :with_salary_range, ->(min, max) do
    where('desired_salary_min >= ? AND desired_salary_max <= ?', min, max)
  end
  scope :with_current_salary, ->(min, max) do
    where('current_salary >= ? AND current_salary <= ?', min, max)
  end
  scope :by_experience_years, ->(min, max) do
    where('years_of_experience >= ? AND years_of_experience <= ?', min, max)
  end
  scope :recent, -> { order(created_at: :desc) }
  scope :alphabetical, -> { order(:last_name, :first_name) }
  scope :active, -> { where(deleted_at: nil) }
  scope :recently_active, -> { where('last_activity_at > ?', 30.days.ago) }
  scope :open_to_remote, -> { where(open_to_remote: true) }
  scope :willing_to_relocate, -> { where(willing_to_relocate: true) }
  scope :available_for_interview, -> { where(available_for_interview: true) }
  scope :with_marketing_consent, -> { where(marketing_consent: true) }
  scope :with_data_processing_consent, -> { where(data_processing_consent: true) }
  scope :with_resume, -> { where.not(resume_url: nil) }
  scope :with_skills, ->(skills) do
    skills_array = Array(skills)
    where("skills ?| array[:skills]", skills: skills_array)
  end
  scope :with_certifications, ->(certs) do
    certs_array = Array(certs)
    where("certifications ?| array[:certs]", certs: certs_array)
  end
  scope :speaks_language, ->(language) do
    where("languages ? :language", language: language)
  end

  # Search scopes (can be enhanced with pg_search)
  scope :search_by_name, ->(query) do
    where(
      'first_name ILIKE :query OR last_name ILIKE :query OR CONCAT(first_name, \' \', last_name) ILIKE :query',
      query: "%#{query}%"
    )
  end

  scope :search_by_email, ->(query) { where('email ILIKE ?', "%#{query}%") }
  
  scope :search_by_content, ->(query) do
    where('bio ILIKE :query OR current_job_title ILIKE :query OR current_company ILIKE :query OR resume_text ILIKE :query',
          query: "%#{query}%")
  end

  scope :search_by_skills, ->(skills) do
    skills_array = Array(skills)
    where("skills ?| array[:skills]", skills: skills_array)
  end

  # Callbacks
  before_save :normalize_email
  before_save :normalize_urls
  before_save :update_last_activity
  before_create :set_defaults

  # Helper methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def initials
    "#{first_name[0]}#{last_name[0]}".upcase
  end

  def formatted_current_salary
    return 'Not specified' if current_salary.blank?
    
    format_salary(current_salary, current_salary_currency)
  end

  def formatted_desired_salary_range
    return 'Not specified' if desired_salary_min.blank? && desired_salary_max.blank?
    
    currency = desired_salary_currency || 'USD'
    
    case
    when desired_salary_min.present? && desired_salary_max.present?
      "#{format_salary(desired_salary_min, currency)} - #{format_salary(desired_salary_max, currency)}"
    when desired_salary_min.present?
      "From #{format_salary(desired_salary_min, currency)}"
    when desired_salary_max.present?
      "Up to #{format_salary(desired_salary_max, currency)}"
    end
  end

  def work_authorization_humanized
    case work_authorization
    when 'citizen' then 'Citizen'
    when 'permanent_resident' then 'Permanent Resident'
    when 'work_visa' then 'Work Visa'
    when 'student_visa' then 'Student Visa'
    when 'needs_sponsorship' then 'Needs Sponsorship'
    else work_authorization&.humanize
    end
  end

  def notice_period_humanized
    case notice_period
    when 'immediate' then 'Available immediately'
    when 'two_weeks' then 'Available in 2 weeks'
    when 'one_month' then 'Available in 1 month'
    when 'two_months' then 'Available in 2 months'
    when 'three_months' then 'Available in 3 months'
    when 'other' then 'Other availability'
    else notice_period&.humanize
    end
  end

  def profile_completeness_percentage
    total_fields = 20
    completed_fields = 0
    
    # Required fields
    completed_fields += 1 if first_name.present?
    completed_fields += 1 if last_name.present?
    completed_fields += 1 if email.present?
    
    # Optional but important fields
    completed_fields += 1 if phone.present?
    completed_fields += 1 if location.present?
    completed_fields += 1 if linkedin_url.present?
    completed_fields += 1 if portfolio_url.present?
    completed_fields += 1 if github_url.present?
    completed_fields += 1 if bio.present?
    completed_fields += 1 if current_job_title.present?
    completed_fields += 1 if current_company.present?
    completed_fields += 1 if years_of_experience.present?
    completed_fields += 1 if current_salary.present?
    completed_fields += 1 if desired_salary_min.present?
    completed_fields += 1 if work_authorization.present?
    completed_fields += 1 if notice_period.present?
    completed_fields += 1 if resume_url.present?
    completed_fields += 1 if skills_list.any?
    completed_fields += 1 if certifications_list.any?
    completed_fields += 1 if languages_list.any?
    
    ((completed_fields.to_f / total_fields) * 100).round
  end

  def has_complete_contact_info?
    email.present? && phone.present? && location.present?
  end

  def needs_visa_sponsorship?
    work_authorization == 'needs_sponsorship'
  end

  def available_immediately?
    notice_period == 'immediate'
  end

  def experience_in_years
    years_of_experience || 0
  end

  def has_resume?
    resume_url.present?
  end

  def is_active?
    deleted_at.nil?
  end

  def recently_active?
    last_activity_at.present? && last_activity_at > 30.days.ago
  end

  def consented_to_marketing?
    marketing_consent? && marketing_consent_at.present?
  end

  def consented_to_data_processing?
    data_processing_consent? && data_processing_consent_at.present?
  end

  # JSON field helpers
  def skills_list
    skills.is_a?(Array) ? skills : []
  end

  def add_skill(skill)
    return if skills_list.include?(skill)
    
    self.skills = skills_list + [skill]
    save
  end

  def remove_skill(skill)
    self.skills = skills_list - [skill]
    save
  end

  def certifications_list
    certifications.is_a?(Array) ? certifications : []
  end

  def add_certification(cert)
    return if certifications_list.include?(cert)
    
    self.certifications = certifications_list + [cert]
    save
  end

  def remove_certification(cert)
    self.certifications = certifications_list - [cert]
    save
  end

  def languages_list
    languages.is_a?(Hash) ? languages : {}
  end

  def add_language(language, proficiency = 'basic')
    langs = languages_list
    langs[language] = proficiency
    self.languages = langs
    save
  end

  def remove_language(language)
    langs = languages_list
    langs.delete(language)
    self.languages = langs
    save
  end

  def preferred_work_types_list
    preferred_work_types.is_a?(Array) ? preferred_work_types : []
  end

  def preferred_locations_list  
    preferred_locations.is_a?(Array) ? preferred_locations : []
  end

  def additional_documents_list
    additional_documents.is_a?(Array) ? additional_documents : []
  end

  # Soft delete
  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def restore!
    update!(deleted_at: nil) if deleted_at.present?
  end

  # GDPR compliance
  def schedule_gdpr_deletion(days_from_now = 30)
    update!(gdpr_delete_after: days_from_now.days.from_now)
  end

  def due_for_gdpr_deletion?
    gdpr_delete_after.present? && gdpr_delete_after <= Time.current
  end

  # Class methods
  def self.search(query)
    return all if query.blank?
    
    search_by_name(query)
      .or(search_by_email(query))
      .or(search_by_content(query))
  end

  def self.popular_skills
    where.not(skills: nil)
      .where.not(skills: [])
      .pluck(:skills)
      .flatten
      .compact
      .tally
      .sort_by { |_, count| -count }
      .first(20)
      .map(&:first)
  end

  def self.gdpr_deletable
    where('gdpr_delete_after <= ?', Time.current)
  end

  private

  def format_salary(amount, currency = 'USD')
    return '' if amount.blank?
    
    # Handle both decimal and integer amounts
    amount_formatted = amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    
    case currency&.upcase
    when 'USD', 'CAD', 'AUD'
      "$#{amount_formatted}"
    when 'EUR'
      "€#{amount_formatted}"
    when 'GBP'
      "£#{amount_formatted}"
    else
      "#{amount_formatted} #{currency}"
    end
  end

  def desired_salary_max_greater_than_min
    return unless desired_salary_min.present? && desired_salary_max.present?
    
    errors.add(:desired_salary_max, 'must be greater than minimum desired salary') if desired_salary_max <= desired_salary_min
  end

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end

  def normalize_urls
    self.linkedin_url = normalize_url(linkedin_url) if linkedin_url.present?
    self.portfolio_url = normalize_url(portfolio_url) if portfolio_url.present?
    self.github_url = normalize_url(github_url) if github_url.present?
  end

  def normalize_url(url)
    return url if url.match?(/\Ahttps?:\/\//)
    
    "https://#{url}"
  end

  def update_last_activity
    self.last_activity_at = Time.current
  end

  def set_defaults
    self.skills = [] if skills.blank?
    self.languages = {} if languages.blank?
    self.certifications = [] if certifications.blank?
    self.preferred_work_types = [] if preferred_work_types.blank?
    self.preferred_locations = [] if preferred_locations.blank?
    self.additional_documents = [] if additional_documents.blank?
    self.marketing_consent = false if marketing_consent.nil?
    self.data_processing_consent = false if data_processing_consent.nil?
    self.available_for_interview = true if available_for_interview.nil?
    self.open_to_remote = false if open_to_remote.nil?
    self.willing_to_relocate = false if willing_to_relocate.nil?
  end
end