# frozen_string_literal: true

class JobsController < ApplicationController
  before_action :set_job, only: %i[show edit update destroy publish close reopen archive unarchive]

  def index
    @jobs = policy_scope(Job).includes(:organization, :hiring_manager, :department)
    @jobs = apply_filters(@jobs)
    authorize @jobs
  end

  def show
    authorize @job
    @job.increment_view_count! unless current_user == @job.hiring_manager
  end

  def new
    @job = current_user.organization.jobs.build
    @job.hiring_manager = current_user
    authorize @job
  end

  def edit
    authorize @job
  end

  def create
    @job = current_user.organization.jobs.build(job_params)
    @job.hiring_manager = current_user
    authorize @job

    if @job.save
      redirect_to @job, notice: "Job was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @job

    if @job.update(job_params)
      redirect_to @job, notice: "Job was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @job

    @job.destroy!
    redirect_to jobs_path, notice: "Job was successfully deleted."
  end

  # State transition actions
  def publish
    authorize @job, :publish?

    if @job.can_be_published?
      @job.publish!
      redirect_to @job, notice: "Job was successfully published."
    else
      errors = @job.publishable_errors.join(", ")
      redirect_to @job, alert: "Cannot publish job: #{errors}"
    end
  rescue StateMachines::InvalidTransition => e
    redirect_to @job, alert: "Cannot publish job: #{e.message}"
  end

  def close
    authorize @job, :close?

    @job.close!
    redirect_to @job, notice: "Job was successfully closed."
  rescue StateMachines::InvalidTransition => e
    redirect_to @job, alert: "Cannot close job: #{e.message}"
  end

  def reopen
    authorize @job, :reopen?

    @job.reopen!
    redirect_to @job, notice: "Job was successfully reopened."
  rescue StateMachines::InvalidTransition => e
    redirect_to @job, alert: "Cannot reopen job: #{e.message}"
  end

  def archive
    authorize @job, :archive?

    @job.archive!
    redirect_to @job, notice: "Job was successfully archived."
  rescue StateMachines::InvalidTransition => e
    redirect_to @job, alert: "Cannot archive job: #{e.message}"
  end

  def unarchive
    authorize @job, :unarchive?

    @job.unarchive!
    redirect_to @job, notice: "Job was successfully unarchived."
  rescue StateMachines::InvalidTransition => e
    redirect_to @job, alert: "Cannot unarchive job: #{e.message}"
  end

  private

  def set_job
    @job = Job.find(params[:id])
  end

  def job_params
    params.expect(
      job: %i[title
              description
              location
              employment_type
              experience_level
              salary_range_min
              salary_range_max
              currency
              remote_work_allowed
              expires_at
              department_id
              requirements
              qualifications
              benefits
              application_instructions]
    )
  end

  def apply_filters(jobs)
    jobs = apply_search_filter(jobs)
    jobs = apply_status_filters(jobs)
    jobs = apply_attribute_filters(jobs)
    jobs = apply_salary_filter(jobs)
    jobs = apply_remote_filter(jobs)
    jobs.recent
  end

  def apply_search_filter(jobs)
    jobs = jobs.search(params[:search]) if params[:search].present?
    jobs
  end

  def apply_status_filters(jobs)
    jobs = jobs.where(status: params[:status]) if params[:status].present? && params[:status] != "all"
    jobs
  end

  def apply_attribute_filters(jobs)
    jobs = jobs.by_employment_type(params[:employment_type]) if valid_filter?(:employment_type)
    jobs = jobs.by_experience_level(params[:experience_level]) if valid_filter?(:experience_level)
    jobs = jobs.where(department_id: params[:department_id]) if valid_filter?(:department_id)
    jobs = jobs.by_location(params[:location]) if params[:location].present?
    jobs
  end

  def apply_salary_filter(jobs)
    if params[:min_salary].present? || params[:max_salary].present?
      jobs = jobs.salary_range(params[:min_salary], params[:max_salary])
    end
    jobs
  end

  def apply_remote_filter(jobs)
    jobs = jobs.remote_friendly if params[:remote_only] == "true"
    jobs
  end

  def valid_filter?(param_key)
    params[param_key].present? && params[param_key] != "all"
  end
end
