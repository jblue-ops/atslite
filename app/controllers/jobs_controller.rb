# frozen_string_literal: true

class JobsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_job, only: %i[show edit update destroy publish close reopen archive unarchive]
  after_action :verify_authorized, except: %i[index search]
  after_action :verify_policy_scoped, only: %i[index search]

  def index
    @jobs = policy_scope(Job)
    @jobs = @jobs.includes(:organization, :hiring_manager, :department)

    # Apply basic filters
    @jobs = @jobs.by_employment_type(params[:employment_type]) if params[:employment_type].present?
    @jobs = @jobs.by_experience_level(params[:experience_level]) if params[:experience_level].present?
    @jobs = @jobs.published if params[:status] == "published"
    @jobs = @jobs.draft if params[:status] == "draft"
    @jobs = @jobs.closed if params[:status] == "closed"
    @jobs = @jobs.archived if params[:status] == "archived"
    @jobs = @jobs.remote_friendly if params[:remote_only] == "1"

    # Basic search
    @jobs = @jobs.search(params[:q]) if params[:q].present?

    @jobs = @jobs.recent.page(params[:page])

    # Advanced search redirect
    redirect_to search_jobs_path(request.query_parameters) if params[:advanced_search] == "1"
  end

  def search
    @search_params = search_params
    @jobs = policy_scope(Job).advanced_search(@search_params)

    # Include associations to prevent N+1 queries
    @jobs = @jobs.includes(
      :organization,
      :hiring_manager,
      :department,
      rich_text_description: :blob,
      rich_text_requirements: :blob,
      rich_text_qualifications: :blob,
      rich_text_benefits: :blob,
      rich_text_application_instructions: :blob
    )

    @jobs = @jobs.recent.page(params[:page])

    # Store search analytics (future enhancement)
    track_search_analytics if @search_params[:query].present?

    render :index
  end

  def show
    authorize @job
    @job.increment_view_count!
    @related_jobs = policy_scope(Job)
      .published
      .where.not(id: @job.id)
      .limit(3)
  end

  def new
    @job = current_organization.jobs.build
    authorize @job
  end

  def edit
    authorize @job
  end

  def create
    @job = current_organization.jobs.build(job_params)
    @job.hiring_manager = current_user
    authorize @job

    if @job.save
      redirect_to @job, notice: "Job posting was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @job

    if @job.update(job_params)
      redirect_to @job, notice: "Job posting was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @job
    @job.destroy!
    redirect_to jobs_path, notice: "Job posting was successfully deleted."
  end

  # State transition actions
  def publish
    authorize @job, :update?

    if @job.can_be_published? && @job.publish
      redirect_to @job, notice: "Job posting was successfully published."
    else
      redirect_to @job, alert: "Cannot publish job: #{@job.publishable_errors.join(", ")}"
    end
  end

  def close
    authorize @job, :update?

    if @job.close
      redirect_to @job, notice: "Job posting was successfully closed."
    else
      redirect_to @job, alert: "Unable to close job posting."
    end
  end

  def reopen
    authorize @job, :update?

    if @job.reopen
      redirect_to @job, notice: "Job posting was successfully reopened."
    else
      redirect_to @job, alert: "Unable to reopen job posting."
    end
  end

  def archive
    authorize @job, :update?

    if @job.archive
      redirect_to @job, notice: "Job posting was successfully archived."
    else
      redirect_to @job, alert: "Unable to archive job posting."
    end
  end

  def unarchive
    authorize @job, :update?

    if @job.unarchive
      redirect_to @job, notice: "Job posting was successfully unarchived."
    else
      redirect_to @job, alert: "Unable to unarchive job posting."
    end
  end

  private

  def set_job
    @job = Job.find(params[:id])
  end

  def job_params
    params.expect(
      job: [:title, :location, :employment_type, :experience_level,
            :salary_range_min, :salary_range_max, :currency,
            :remote_work_allowed, :expires_at, :department_id,
            :description, :requirements, :qualifications,
            :benefits, :application_instructions,
            { settings: {} }]
    )
  end

  def search_params
    params.permit(
      :query, :title, :location, :employment_type, :experience_level,
      :min_salary, :max_salary, :remote_only, :status, :expiration,
      :published_after, :published_before, :page
    ).to_h.with_indifferent_access
  end

  def current_organization
    current_user.organization
  end

  def track_search_analytics
    # Future: Track search terms for analytics and autocomplete
    # Could store in Redis or separate analytics table
  end
end
