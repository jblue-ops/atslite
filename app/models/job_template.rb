# frozen_string_literal: true

class JobTemplate < ApplicationRecord
  # Multi-tenant association
  belongs_to :organization, optional: false
  belongs_to :department, optional: true
  belongs_to :created_by, class_name: "User", optional: false
  belongs_to :last_used_by, class_name: "User", optional: true
  belongs_to :parent_template, class_name: "JobTemplate", optional: true

  # Template versioning/forking relationships
  has_many :child_templates, class_name: "JobTemplate", foreign_key: :parent_template_id, dependent: :destroy
  has_many :jobs, dependent: :nullify, inverse_of: :job_template

  # Rich text content (matching Job model structure)
  has_rich_text :template_description
  has_rich_text :template_requirements
  has_rich_text :template_qualifications
  has_rich_text :template_benefits
  has_rich_text :template_application_instructions

  # Validations
  validates :name, presence: true, length: { minimum: 3, maximum: 200 }
  validates :name, uniqueness: { scope: :organization_id, message: "already exists in this organization" }
  validates :category, inclusion: {
    in: %w[engineering sales marketing design hr finance operations customer_success product legal executive other],
    message: "must be a valid category"
  }
  validates :employment_type, inclusion: {
    in: %w[full_time part_time contract temporary internship],
    message: "must be a valid employment type"
  }, allow_blank: true
  validates :experience_level, inclusion: {
    in: %w[entry junior mid senior lead executive],
    message: "must be a valid experience level"
  }, allow_blank: true
  validates :currency, format: { with: /\A[A-Z]{3}\z/, message: "must be a valid 3-letter currency code" },
                       allow_blank: true
  validates :salary_range_min, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :salary_range_max, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :usage_count, numericality: { greater_than_or_equal_to: 0 }
  validates :version, numericality: { greater_than_or_equal_to: 1 }
  validate :salary_range_consistency
  validate :created_by_belongs_to_organization
  validate :last_used_by_belongs_to_organization
  validate :only_one_default_per_category_per_organization
  validate :parent_template_belongs_to_same_organization

  # Scopes for easy querying
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :default_templates, -> { where(is_default: true) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_department, ->(department) { where(department: department) }
  scope :recently_used, -> { order(last_used_at: :desc) }
  scope :most_used, -> { order(usage_count: :desc) }
  scope :by_organization, ->(org) { where(organization: org) }
  scope :with_tags, ->(tags) { where("tags ILIKE ANY (ARRAY[?])", tags.map { |tag| "%#{tag}%" }) }
  scope :created_by_user, ->(user) { where(created_by: user) }
  scope :root_templates, -> { where(parent_template_id: nil) }
  scope :template_versions, ->(parent_id) { where(parent_template_id: parent_id) }

  # Enums for consistent category management
  enum :category, {
    engineering: "engineering",
    sales: "sales",
    marketing: "marketing",
    design: "design",
    hr: "hr",
    finance: "finance",
    operations: "operations",
    customer_success: "customer_success",
    product: "product",
    legal: "legal",
    executive: "executive",
    other: "other"
  }, validate: true, prefix: :category

  enum :employment_type, {
    full_time: "full_time",
    part_time: "part_time",
    contract: "contract",
    temporary: "temporary",
    internship: "internship"
  }, validate: { allow_blank: true }

  enum :experience_level, {
    entry: "entry",
    junior: "junior",
    mid: "mid",
    senior: "senior",
    lead: "lead",
    executive: "executive"
  }, validate: { allow_blank: true }, prefix: :level

  # Callbacks
  before_validation :normalize_fields
  before_save :update_version_on_content_change
  after_create :set_default_settings

  # Multi-tenant support
  acts_as_tenant :organization

  # Class methods
  def self.search(query)
    return none if query.blank?

    where(
      "name ILIKE :query OR title ILIKE :query OR tags ILIKE :query OR description ILIKE :query",
      query: "%#{query}%"
    )
  end

  def self.by_tag(tag)
    where("tags ILIKE ?", "%#{tag}%")
  end

  def self.popular(limit = 10)
    active.order(usage_count: :desc).limit(limit)
  end

  def self.categories_with_counts(organization)
    where(organization: organization, is_active: true)
      .group(:category)
      .count
  end

  # Instance methods
  def display_name
    name.presence || "Untitled Template"
  end

  def category_display
    category.humanize.titleize
  end

  def employment_type_display
    employment_type&.humanize&.titleize || "Not specified"
  end

  def experience_level_display
    experience_level&.humanize&.titleize || "Not specified"
  end

  def tags_array
    return [] if tags.blank?

    tags.split(",").map(&:strip).compact_blank
  end

  def tags_array=(tag_array)
    self.tags = tag_array.join(", ") if tag_array.is_a?(Array)
  end

  def add_tag(tag)
    current_tags = tags_array
    current_tags << tag.strip unless current_tags.include?(tag.strip)
    self.tags_array = current_tags
  end

  def remove_tag(tag)
    current_tags = tags_array
    current_tags.delete(tag.strip)
    self.tags_array = current_tags
  end

  def has_tag?(tag)
    tags_array.include?(tag)
  end

  def salary_range_display
    return "Salary not specified" if salary_range_min.blank? && salary_range_max.blank?
    return "#{currency} #{formatted_salary(salary_range_min)}+" if salary_range_max.blank?
    return "Up to #{currency} #{formatted_salary(salary_range_max)}" if salary_range_min.blank?

    "#{currency} #{formatted_salary(salary_range_min)} - #{formatted_salary(salary_range_max)}"
  end

  def increment_usage!
    increment!(:usage_count)
    update_column(:last_used_at, Time.current)
  end

  def mark_used_by!(user)
    increment!(:usage_count)
    update_columns(
      last_used_at: Time.current,
      last_used_by_id: user.id
    )
  end

  def deactivate!
    update!(is_active: false)
  end

  def activate!
    update!(is_active: true)
  end

  def make_default!
    transaction do
      # Remove default status from other templates in same category
      self.class.where(
        organization: organization,
        category: category,
        is_default: true
      ).where.not(id: id).update_all(is_default: false)

      update!(is_default: true)
    end
  end

  def remove_default!
    update!(is_default: false)
  end

  def duplicate!(new_name: nil, created_by_user: nil)
    new_name ||= "#{name} (Copy)"
    created_by_user ||= created_by

    new_template = dup
    new_template.assign_attributes(
      name: new_name,
      created_by: created_by_user,
      parent_template: self,
      version: 1,
      usage_count: 0,
      last_used_at: nil,
      last_used_by: nil,
      is_default: false
    )

    # Copy rich text content
    new_template.template_description = template_description.body.to_s if template_description.present?

    new_template.template_requirements = template_requirements.body.to_s if template_requirements.present?

    new_template.template_qualifications = template_qualifications.body.to_s if template_qualifications.present?

    new_template.template_benefits = template_benefits.body.to_s if template_benefits.present?

    if template_application_instructions.present?
      new_template.template_application_instructions = template_application_instructions.body.to_s
    end

    new_template.save!
    new_template
  end

  # Core method: Apply template to create a new Job
  def apply_to_job!(job_attributes = {}, user: nil)
    # Validate that the user can create jobs in this organization
    if user && user.organization != organization
      raise ArgumentError, "User must belong to the same organization as the template"
    end

    # Start with template attributes
    template_attrs = extract_job_attributes

    # Merge with provided attributes (provided attributes override template)
    final_attrs = template_attrs.merge(job_attributes.symbolize_keys)

    # Ensure required associations are set
    final_attrs[:organization] = organization
    final_attrs[:hiring_manager] ||= user if user&.can_manage_jobs?

    job = Job.new(final_attrs)

    # Copy rich text content
    copy_rich_text_to_job(job)

    # Apply default job settings from template
    job.settings = (job.settings || {}).merge(default_job_settings) if default_job_settings.present?

    # Mark template as used
    mark_used_by!(user) if user

    job
  end

  def create_job_from_template!(job_attributes = {}, user: nil)
    job = apply_to_job!(job_attributes, user: user)

    raise ActiveRecord::RecordInvalid, job unless job.save

    # Create the association
    job.update_column(:job_template_id, id) if job.persisted?
    job
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

  def default_job_setting(key)
    default_job_settings[key.to_s]
  end

  def set_default_job_setting!(key, value)
    self.default_job_settings = default_job_settings.merge(key.to_s => value)
    save!
  end

  def remove_default_job_setting!(key)
    self.default_job_settings = default_job_settings.except(key.to_s)
    save!
  end

  def has_content?
    template_description.present? ||
      template_requirements.present? ||
      template_qualifications.present? ||
      template_benefits.present? ||
      template_application_instructions.present?
  end

  def content_complete?
    title.present? &&
      template_description.present? &&
      employment_type.present?
  end

  def is_root_template?
    parent_template_id.nil?
  end

  def version_chain
    return [self] if is_root_template?

    chain = []
    current = self
    while current.present?
      chain.unshift(current)
      current = current.parent_template
    end
    chain
  end

  def latest_version
    return self if is_root_template?

    root_template = version_chain.first
    root_template.child_templates.order(:version).last || root_template
  end

  private

  def extract_job_attributes
    {
      title: title,
      location: location,
      employment_type: employment_type,
      experience_level: experience_level,
      salary_range_min: salary_range_min,
      salary_range_max: salary_range_max,
      currency: currency,
      remote_work_allowed: remote_work_allowed,
      department: department,
      job_template_id: id
    }.compact
  end

  def copy_rich_text_to_job(job)
    job.description = template_description.body.to_s if template_description.present?
    job.requirements = template_requirements.body.to_s if template_requirements.present?
    job.qualifications = template_qualifications.body.to_s if template_qualifications.present?
    job.benefits = template_benefits.body.to_s if template_benefits.present?
    return if template_application_instructions.blank?

    job.application_instructions = template_application_instructions.body.to_s
  end

  def salary_range_consistency
    return if salary_range_min.blank? || salary_range_max.blank?

    return unless salary_range_min > salary_range_max

    errors.add(:salary_range_max, "must be greater than or equal to minimum salary")
  end

  def created_by_belongs_to_organization
    return if created_by.blank? || organization.blank?

    return if created_by.organization_id == organization.id

    errors.add(:created_by, "must belong to the same organization")
  end

  def last_used_by_belongs_to_organization
    return if last_used_by.blank? || organization.blank?

    return if last_used_by.organization_id == organization.id

    errors.add(:last_used_by, "must belong to the same organization")
  end

  def only_one_default_per_category_per_organization
    return unless is_default?

    existing_default = self.class.where(
      organization: organization,
      category: category,
      is_default: true
    ).where.not(id: id).exists?

    return unless existing_default

    errors.add(:is_default, "can only have one default template per category")
  end

  def parent_template_belongs_to_same_organization
    return if parent_template.blank?

    return if parent_template.organization_id == organization_id

    errors.add(:parent_template, "must belong to the same organization")
  end

  def normalize_fields
    self.name = name&.strip&.squeeze(" ")
    self.title = title&.strip&.squeeze(" ")
    self.location = location&.strip
    self.currency = currency&.upcase if currency.present?
    self.tags = tags&.strip
  end

  def update_version_on_content_change
    return unless persisted? && will_save_change_to_any_content_field?

    # Only increment version for content changes, not metadata changes
    self.version += 1
  end

  def will_save_change_to_any_content_field?
    content_fields = %w[
      title location employment_type experience_level
      salary_range_min salary_range_max currency remote_work_allowed
    ]

    content_fields.any? { |field| will_save_change_to_attribute?(field) } ||
      template_description.changed? ||
      template_requirements.changed? ||
      template_qualifications.changed? ||
      template_benefits.changed? ||
      template_application_instructions.changed?
  end

  def set_default_settings
    return unless persisted?

    default_template_settings = {
      "auto_apply_department" => true,
      "preserve_rich_text_formatting" => true,
      "notify_on_usage" => false,
      "track_job_performance" => true
    }

    default_job_settings_values = {
      "auto_reject_after_days" => 30,
      "send_confirmation_email" => true,
      "allow_cover_letters" => true,
      "screening_questions_required" => false,
      "notify_hiring_manager" => true
    }

    self.settings = default_template_settings.merge(settings || {})
    self.default_job_settings = default_job_settings_values.merge(default_job_settings || {})

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
