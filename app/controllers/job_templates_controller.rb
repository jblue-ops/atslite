# frozen_string_literal: true

class JobTemplatesController < ApplicationController
  before_action :set_job_template, only: %i[show edit update destroy activate deactivate use_template]

  def index
    @job_templates = policy_scope(JobTemplate).includes(:organization, :created_by, :department)
    @job_templates = apply_filters(@job_templates)
    authorize @job_templates
  end

  def show
    authorize @job_template
  end

  def new
    @job_template = current_user.organization.job_templates.build
    @job_template.created_by = current_user

    # Handle template duplication
    if params[:duplicate].present?
      source_template = JobTemplate.find(params[:duplicate])
      authorize source_template, :show?
      duplicate_template_attributes(source_template)
    end

    authorize @job_template
  end

  def edit
    authorize @job_template
  end

  def create
    @job_template = current_user.organization.job_templates.build(job_template_params)
    @job_template.created_by = current_user
    authorize @job_template

    if @job_template.save
      redirect_to @job_template, notice: "Job template was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @job_template

    if @job_template.update(job_template_params)
      redirect_to @job_template, notice: "Job template was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @job_template

    @job_template.destroy!
    redirect_to job_templates_path, notice: "Job template was successfully deleted."
  end

  # Template management actions
  def activate
    authorize @job_template, :activate?

    @job_template.activate!
    redirect_to @job_template, notice: "Template was successfully activated."
  end

  def deactivate
    authorize @job_template, :deactivate?

    @job_template.deactivate!
    redirect_to @job_template, notice: "Template was successfully deactivated."
  end

  # Create job from template
  def use_template
    authorize @job_template, :use?

    job = @job_template.create_job_from_template(current_user)

    if job
      redirect_to edit_job_path(job), notice: "Job created from template. Review and publish when ready."
    else
      redirect_to @job_template, alert: "Unable to create job from template. Please try again."
    end
  end

  private

  def set_job_template
    @job_template = JobTemplate.find(params[:id])
  end

  def job_template_params
    params.expect(
      job_template: %i[name
                       description
                       category
                       tags
                       title
                       location
                       employment_type
                       experience_level
                       salary_range_min
                       salary_range_max
                       currency
                       remote_work_allowed
                       department_id
                       template_description
                       template_requirements
                       template_qualifications
                       template_benefits
                       template_application_instructions
                       is_active
                       is_default]
    )
  end

  def apply_filters(templates)
    templates = apply_search_filter(templates)
    templates = apply_category_filter(templates)
    templates = apply_status_filter(templates)
    templates = apply_created_by_filter(templates)
    templates.recent
  end

  def apply_search_filter(templates)
    templates = templates.search(params[:search]) if params[:search].present?
    templates
  end

  def apply_category_filter(templates)
    templates = templates.by_category(params[:category]) if params[:category].present? && params[:category] != "all"
    templates
  end

  def apply_status_filter(templates)
    case params[:status]
    when "active"
      templates.active
    when "inactive"
      templates.inactive
    else
      templates
    end
  end

  def apply_created_by_filter(templates)
    templates = templates.by_created_by(current_user) if params[:created_by_me] == "true"
    templates
  end

  def duplicate_template_attributes(source_template)
    @job_template.assign_attributes(
      name: "Copy of #{source_template.name}",
      description: source_template.description,
      category: source_template.category,
      tags: source_template.tags,
      title: source_template.title,
      location: source_template.location,
      employment_type: source_template.employment_type,
      experience_level: source_template.experience_level,
      salary_range_min: source_template.salary_range_min,
      salary_range_max: source_template.salary_range_max,
      currency: source_template.currency,
      remote_work_allowed: source_template.remote_work_allowed,
      department: source_template.department,
      template_description: source_template.template_description,
      template_requirements: source_template.template_requirements,
      template_qualifications: source_template.template_qualifications,
      template_benefits: source_template.template_benefits,
      template_application_instructions: source_template.template_application_instructions,
      is_active: false, # New duplicated templates start as inactive
      parent_template: source_template
    )
  end
end
