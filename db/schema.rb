# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_30_120007) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "job_id", null: false
    t.uuid "candidate_id", null: false
    t.uuid "stage_changed_by_id"
    t.string "status", default: "applied", null: false
    t.string "source", limit: 100
    t.datetime "applied_at", null: false
    t.datetime "stage_changed_at"
    t.datetime "rejected_at"
    t.text "cover_letter"
    t.text "notes"
    t.integer "rating"
    t.string "rejection_reason", limit: 255
    t.integer "salary_offered"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["applied_at"], name: "index_applications_on_applied_at"
    t.index ["candidate_id", "job_id"], name: "index_applications_on_candidate_and_job_unique", unique: true
    t.index ["candidate_id", "status"], name: "index_applications_on_candidate_and_status"
    t.index ["candidate_id"], name: "index_applications_on_candidate_id"
    t.index ["company_id", "applied_at"], name: "index_applications_on_company_and_applied_at"
    t.index ["company_id", "status"], name: "index_applications_on_company_and_status"
    t.index ["company_id"], name: "index_applications_on_company_id"
    t.index ["job_id", "applied_at"], name: "index_applications_on_job_and_applied_at"
    t.index ["job_id", "status"], name: "index_applications_on_job_and_status"
    t.index ["job_id"], name: "index_applications_on_job_id"
    t.index ["metadata"], name: "index_applications_on_metadata", using: :gin
    t.index ["rating"], name: "index_applications_on_rating"
    t.index ["rejected_at"], name: "index_applications_on_rejected_at"
    t.index ["salary_offered"], name: "index_applications_on_salary_offered"
    t.index ["stage_changed_at"], name: "index_applications_on_stage_changed_at"
    t.index ["stage_changed_by_id"], name: "index_applications_on_stage_changed_by_id"
    t.index ["status"], name: "index_applications_on_status"
    t.check_constraint "applied_at IS NOT NULL", name: "applications_applied_at_not_null_check"
    t.check_constraint "rating IS NULL OR rating >= 1 AND rating <= 5", name: "applications_rating_check"
    t.check_constraint "salary_offered IS NULL OR salary_offered >= 0", name: "applications_salary_offered_check"
    t.check_constraint "status::text = 'rejected'::text AND rejected_at IS NOT NULL OR status::text <> 'rejected'::text AND rejected_at IS NULL", name: "applications_rejection_consistency_check"
    t.check_constraint "status::text = ANY (ARRAY['applied'::character varying, 'screening'::character varying, 'phone_interview'::character varying, 'technical_interview'::character varying, 'final_interview'::character varying, 'offer'::character varying, 'accepted'::character varying, 'rejected'::character varying, 'withdrawn'::character varying]::text[])", name: "applications_status_check"
  end

  create_table "candidates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "first_name", limit: 50, null: false
    t.string "last_name", limit: 100, null: false
    t.string "phone"
    t.string "location", limit: 100
    t.string "linkedin_url"
    t.string "portfolio_url"
    t.string "github_url"
    t.text "bio"
    t.string "current_job_title", limit: 100
    t.string "current_company", limit: 100
    t.integer "years_of_experience"
    t.decimal "current_salary", precision: 12, scale: 2
    t.string "current_salary_currency", limit: 3, default: "USD"
    t.decimal "desired_salary_min", precision: 12, scale: 2
    t.decimal "desired_salary_max", precision: 12, scale: 2
    t.string "desired_salary_currency", limit: 3, default: "USD"
    t.string "work_authorization"
    t.string "notice_period"
    t.boolean "open_to_remote", default: false, null: false
    t.boolean "willing_to_relocate", default: false, null: false
    t.boolean "available_for_interview", default: true, null: false
    t.string "resume_url"
    t.text "resume_text"
    t.jsonb "skills", default: [], null: false
    t.jsonb "languages", default: {}, null: false
    t.jsonb "certifications", default: [], null: false
    t.jsonb "preferred_work_types", default: [], null: false
    t.jsonb "preferred_locations", default: [], null: false
    t.jsonb "additional_documents", default: [], null: false
    t.boolean "marketing_consent", default: false, null: false
    t.datetime "marketing_consent_at"
    t.boolean "data_processing_consent", default: false, null: false
    t.datetime "data_processing_consent_at"
    t.datetime "last_activity_at"
    t.datetime "gdpr_delete_after"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["additional_documents"], name: "index_candidates_on_additional_documents", using: :gin
    t.index ["available_for_interview", "deleted_at"], name: "index_candidates_on_available_and_active"
    t.index ["available_for_interview"], name: "index_candidates_on_available_for_interview"
    t.index ["bio"], name: "index_candidates_on_bio", opclass: :gin_trgm_ops, using: :gin
    t.index ["certifications"], name: "index_candidates_on_certifications", using: :gin
    t.index ["created_at"], name: "index_candidates_on_created_at"
    t.index ["current_company"], name: "index_candidates_on_current_company"
    t.index ["current_job_title"], name: "index_candidates_on_current_job_title"
    t.index ["current_salary"], name: "index_candidates_on_current_salary"
    t.index ["data_processing_consent", "data_processing_consent_at"], name: "index_candidates_on_data_consent"
    t.index ["deleted_at"], name: "index_candidates_on_deleted_at"
    t.index ["desired_salary_max"], name: "index_candidates_on_desired_salary_max"
    t.index ["desired_salary_min", "desired_salary_max"], name: "index_candidates_on_desired_salary_range"
    t.index ["desired_salary_min"], name: "index_candidates_on_desired_salary_min"
    t.index ["email"], name: "index_candidates_on_email", unique: true
    t.index ["first_name", "last_name"], name: "index_candidates_on_full_name"
    t.index ["first_name"], name: "index_candidates_on_first_name"
    t.index ["gdpr_delete_after"], name: "index_candidates_on_gdpr_delete_after"
    t.index ["languages"], name: "index_candidates_on_languages", using: :gin
    t.index ["last_activity_at", "deleted_at"], name: "index_candidates_on_activity_and_active"
    t.index ["last_activity_at"], name: "index_candidates_on_last_activity_at"
    t.index ["last_name"], name: "index_candidates_on_last_name"
    t.index ["location"], name: "index_candidates_on_location"
    t.index ["marketing_consent", "marketing_consent_at"], name: "index_candidates_on_marketing_consent"
    t.index ["notice_period"], name: "index_candidates_on_notice_period"
    t.index ["open_to_remote", "willing_to_relocate"], name: "index_candidates_on_remote_and_relocate"
    t.index ["open_to_remote"], name: "index_candidates_on_open_to_remote"
    t.index ["preferred_locations"], name: "index_candidates_on_preferred_locations", using: :gin
    t.index ["preferred_work_types"], name: "index_candidates_on_preferred_work_types", using: :gin
    t.index ["resume_text"], name: "index_candidates_on_resume_text", opclass: :gin_trgm_ops, using: :gin
    t.index ["skills"], name: "index_candidates_on_skills", using: :gin
    t.index ["willing_to_relocate"], name: "index_candidates_on_willing_to_relocate"
    t.index ["work_authorization", "years_of_experience"], name: "index_candidates_on_auth_and_experience"
    t.index ["work_authorization"], name: "index_candidates_on_work_authorization"
    t.index ["years_of_experience"], name: "index_candidates_on_years_of_experience"
    t.check_constraint "(current_salary IS NULL OR current_salary >= 0::numeric) AND (desired_salary_min IS NULL OR desired_salary_min >= 0::numeric) AND (desired_salary_max IS NULL OR desired_salary_max >= 0::numeric)", name: "candidates_salary_positive_check"
    t.check_constraint "(current_salary_currency IS NULL OR length(current_salary_currency::text) = 3) AND (desired_salary_currency IS NULL OR length(desired_salary_currency::text) = 3)", name: "candidates_currency_format_check"
    t.check_constraint "bio IS NULL OR length(bio) <= 2000", name: "candidates_bio_length_check"
    t.check_constraint "data_processing_consent = false AND data_processing_consent_at IS NULL OR data_processing_consent = true AND data_processing_consent_at IS NOT NULL", name: "candidates_data_processing_consent_at_check"
    t.check_constraint "desired_salary_min IS NULL OR desired_salary_max IS NULL OR desired_salary_max >= desired_salary_min", name: "candidates_desired_salary_range_check"
    t.check_constraint "email::text ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+.[A-Za-z]{2,}$'::text", name: "candidates_email_format_check"
    t.check_constraint "gdpr_delete_after IS NULL OR gdpr_delete_after > created_at", name: "candidates_gdpr_delete_future_check"
    t.check_constraint "github_url IS NULL OR github_url::text ~* '^https?://(www\\.)?github\\.com/[\\w\\-]+/?$'::text", name: "candidates_github_format_check"
    t.check_constraint "length(TRIM(BOTH FROM first_name)) > 0", name: "candidates_first_name_not_empty_check"
    t.check_constraint "length(TRIM(BOTH FROM last_name)) > 0", name: "candidates_last_name_not_empty_check"
    t.check_constraint "linkedin_url IS NULL OR linkedin_url::text ~* '^https?://(www\\.)?linkedin\\.com/in/[\\w\\-]+/?$'::text", name: "candidates_linkedin_format_check"
    t.check_constraint "marketing_consent = false AND marketing_consent_at IS NULL OR marketing_consent = true AND marketing_consent_at IS NOT NULL", name: "candidates_marketing_consent_at_check"
    t.check_constraint "notice_period IS NULL OR (notice_period::text = ANY (ARRAY['immediate'::character varying, 'two_weeks'::character varying, 'one_month'::character varying, 'two_months'::character varying, 'three_months'::character varying, 'other'::character varying]::text[]))", name: "candidates_notice_period_check"
    t.check_constraint "phone IS NULL OR phone::text ~ '^[\\+\\d\\s\\-\\(\\)\\.]+$'::text", name: "candidates_phone_format_check"
    t.check_constraint "portfolio_url IS NULL OR portfolio_url::text ~* '^https?://'::text", name: "candidates_portfolio_url_format_check"
    t.check_constraint "work_authorization IS NULL OR (work_authorization::text = ANY (ARRAY['citizen'::character varying, 'permanent_resident'::character varying, 'work_visa'::character varying, 'student_visa'::character varying, 'needs_sponsorship'::character varying]::text[]))", name: "candidates_work_authorization_check"
    t.check_constraint "years_of_experience IS NULL OR years_of_experience >= 0 AND years_of_experience < 70", name: "candidates_years_experience_check"
  end

  create_table "companies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "email_domain"
    t.integer "subscription_plan", default: 0, null: false
    t.jsonb "settings", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_domain"], name: "index_companies_on_email_domain"
    t.index ["name"], name: "index_companies_on_name"
    t.index ["settings"], name: "index_companies_on_settings", using: :gin
    t.index ["slug"], name: "index_companies_on_slug", unique: true
    t.index ["subscription_plan"], name: "index_companies_on_subscription_plan"
    t.check_constraint "email_domain IS NULL OR email_domain::text ~ '^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?.[a-zA-Z]{2,}$'::text", name: "companies_email_domain_format_check"
    t.check_constraint "slug::text ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'::text", name: "companies_slug_format_check"
    t.check_constraint "subscription_plan = ANY (ARRAY[0, 1, 2])", name: "companies_subscription_plan_check"
  end

  create_table "interviews", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "application_id", null: false
    t.uuid "interviewer_id", null: false
    t.uuid "scheduled_by_id"
    t.string "interview_type", null: false
    t.string "status", default: "scheduled", null: false
    t.datetime "scheduled_at", null: false
    t.integer "duration_minutes", default: 60
    t.string "location", limit: 255
    t.string "video_link", limit: 500
    t.string "calendar_event_id", limit: 100
    t.text "feedback"
    t.integer "rating"
    t.string "decision"
    t.datetime "completed_at"
    t.text "notes"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id", "scheduled_at"], name: "index_interviews_on_application_and_scheduled_at"
    t.index ["application_id", "status"], name: "index_interviews_on_application_and_status"
    t.index ["application_id"], name: "index_interviews_on_application_id"
    t.index ["completed_at"], name: "index_interviews_on_completed_at"
    t.index ["decision"], name: "index_interviews_on_decision"
    t.index ["duration_minutes"], name: "index_interviews_on_duration_minutes"
    t.index ["interview_type"], name: "index_interviews_on_interview_type"
    t.index ["interviewer_id", "scheduled_at"], name: "index_interviews_on_interviewer_and_scheduled_at"
    t.index ["interviewer_id", "status"], name: "index_interviews_on_interviewer_and_status"
    t.index ["interviewer_id"], name: "index_interviews_on_interviewer_id"
    t.index ["metadata"], name: "index_interviews_on_metadata", using: :gin
    t.index ["rating"], name: "index_interviews_on_rating"
    t.index ["scheduled_at", "status"], name: "index_interviews_on_date_and_status"
    t.index ["scheduled_at"], name: "index_interviews_on_scheduled_at"
    t.index ["scheduled_by_id", "scheduled_at"], name: "index_interviews_on_scheduled_by_and_date"
    t.index ["scheduled_by_id"], name: "index_interviews_on_scheduled_by_id"
    t.index ["status", "scheduled_at"], name: "index_interviews_on_status_and_scheduled_at"
    t.index ["status"], name: "index_interviews_on_status"
    t.check_constraint "decision IS NULL OR (decision::text = ANY (ARRAY['strong_yes'::character varying, 'yes'::character varying, 'maybe'::character varying, 'no'::character varying, 'strong_no'::character varying]::text[]))", name: "interviews_decision_check"
    t.check_constraint "duration_minutes IS NULL OR duration_minutes > 0", name: "interviews_duration_check"
    t.check_constraint "interview_type::text = ANY (ARRAY['phone'::character varying, 'video'::character varying, 'onsite'::character varying, 'technical'::character varying, 'behavioral'::character varying, 'panel'::character varying]::text[])", name: "interviews_interview_type_check"
    t.check_constraint "rating IS NULL OR rating >= 1 AND rating <= 5", name: "interviews_rating_check"
    t.check_constraint "scheduled_at IS NOT NULL", name: "interviews_scheduled_at_not_null_check"
    t.check_constraint "status::text = 'completed'::text AND completed_at IS NOT NULL OR status::text <> 'completed'::text AND completed_at IS NULL", name: "interviews_completion_consistency_check"
    t.check_constraint "status::text = ANY (ARRAY['scheduled'::character varying, 'confirmed'::character varying, 'completed'::character varying, 'cancelled'::character varying, 'no_show'::character varying]::text[])", name: "interviews_status_check"
  end

  create_table "jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.text "requirements"
    t.uuid "company_id", null: false
    t.string "department"
    t.uuid "hiring_manager_id"
    t.string "employment_type", null: false
    t.string "experience_level", null: false
    t.string "work_location_type", null: false
    t.string "location", limit: 100
    t.decimal "salary_min", precision: 12, scale: 2
    t.decimal "salary_max", precision: 12, scale: 2
    t.string "salary_currency", limit: 3
    t.string "salary_period"
    t.string "status", default: "draft", null: false
    t.boolean "active", default: true, null: false
    t.boolean "confidential", default: false, null: false
    t.boolean "remote_work_eligible", default: false, null: false
    t.datetime "posted_at"
    t.datetime "application_deadline"
    t.datetime "target_start_date"
    t.string "urgency"
    t.integer "openings_count", default: 1
    t.string "referral_bonus_amount", limit: 50
    t.text "benefits"
    t.text "company_overview"
    t.jsonb "required_skills", default: [], null: false
    t.jsonb "nice_to_have_skills", default: [], null: false
    t.jsonb "pipeline_stages", default: [], null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "deleted_at"], name: "index_jobs_on_active_and_not_deleted"
    t.index ["active"], name: "index_jobs_on_active"
    t.index ["application_deadline"], name: "index_jobs_on_application_deadline"
    t.index ["company_id", "status"], name: "index_jobs_on_company_and_status"
    t.index ["company_id"], name: "index_jobs_on_company_id"
    t.index ["confidential"], name: "index_jobs_on_confidential"
    t.index ["deleted_at"], name: "index_jobs_on_deleted_at"
    t.index ["department"], name: "index_jobs_on_department"
    t.index ["description"], name: "index_jobs_on_description", opclass: :gin_trgm_ops, using: :gin
    t.index ["employment_type", "experience_level"], name: "index_jobs_on_employment_and_experience"
    t.index ["employment_type"], name: "index_jobs_on_employment_type"
    t.index ["experience_level"], name: "index_jobs_on_experience_level"
    t.index ["hiring_manager_id"], name: "index_jobs_on_hiring_manager_id"
    t.index ["location"], name: "index_jobs_on_location"
    t.index ["nice_to_have_skills"], name: "index_jobs_on_nice_to_have_skills", using: :gin
    t.index ["pipeline_stages"], name: "index_jobs_on_pipeline_stages", using: :gin
    t.index ["posted_at"], name: "index_jobs_on_posted_at"
    t.index ["remote_work_eligible"], name: "index_jobs_on_remote_work_eligible"
    t.index ["required_skills"], name: "index_jobs_on_required_skills", using: :gin
    t.index ["requirements"], name: "index_jobs_on_requirements", opclass: :gin_trgm_ops, using: :gin
    t.index ["salary_currency"], name: "index_jobs_on_salary_currency"
    t.index ["salary_max"], name: "index_jobs_on_salary_max"
    t.index ["salary_min", "salary_max", "salary_currency"], name: "index_jobs_on_salary_range"
    t.index ["salary_min"], name: "index_jobs_on_salary_min"
    t.index ["status", "posted_at"], name: "index_jobs_on_status_and_posted_date"
    t.index ["status"], name: "index_jobs_on_status"
    t.index ["title"], name: "index_jobs_on_title"
    t.index ["urgency"], name: "index_jobs_on_urgency"
    t.index ["work_location_type", "remote_work_eligible"], name: "index_jobs_on_location_type_and_remote"
    t.index ["work_location_type"], name: "index_jobs_on_work_location_type"
    t.check_constraint "(salary_min IS NULL OR salary_min >= 0::numeric) AND (salary_max IS NULL OR salary_max >= 0::numeric)", name: "jobs_salary_positive_check"
    t.check_constraint "employment_type::text = ANY (ARRAY['full_time'::character varying, 'part_time'::character varying, 'contract'::character varying, 'internship'::character varying, 'temporary'::character varying]::text[])", name: "jobs_employment_type_check"
    t.check_constraint "experience_level::text = ANY (ARRAY['entry'::character varying, 'mid'::character varying, 'senior'::character varying, 'executive'::character varying]::text[])", name: "jobs_experience_level_check"
    t.check_constraint "length(TRIM(BOTH FROM title)) >= 3", name: "jobs_title_not_empty_check"
    t.check_constraint "openings_count IS NULL OR openings_count > 0", name: "jobs_openings_count_positive_check"
    t.check_constraint "posted_at IS NULL OR application_deadline IS NULL OR application_deadline > posted_at", name: "jobs_posted_before_deadline_check"
    t.check_constraint "posted_at IS NULL OR target_start_date IS NULL OR target_start_date > posted_at", name: "jobs_posted_before_start_check"
    t.check_constraint "salary_currency IS NULL OR length(salary_currency::text) = 3", name: "jobs_currency_format_check"
    t.check_constraint "salary_min IS NULL OR salary_max IS NULL OR salary_max >= salary_min", name: "jobs_salary_range_check"
    t.check_constraint "salary_period IS NULL OR (salary_period::text = ANY (ARRAY['hourly'::character varying, 'daily'::character varying, 'weekly'::character varying, 'monthly'::character varying, 'annually'::character varying]::text[]))", name: "jobs_salary_period_check"
    t.check_constraint "status::text <> 'published'::text OR posted_at IS NOT NULL", name: "jobs_published_has_posted_at_check"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'published'::character varying, 'paused'::character varying, 'closed'::character varying, 'archived'::character varying]::text[])", name: "jobs_status_check"
    t.check_constraint "urgency IS NULL OR (urgency::text = ANY (ARRAY['low'::character varying, 'medium'::character varying, 'high'::character varying, 'urgent'::character varying]::text[]))", name: "jobs_urgency_check"
    t.check_constraint "work_location_type::text = ANY (ARRAY['on_site'::character varying, 'hybrid'::character varying, 'remote'::character varying]::text[])", name: "jobs_work_location_type_check"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.integer "role", default: 0, null: false
    t.jsonb "settings", default: {}, null: false
    t.datetime "last_login_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "email"], name: "index_users_on_company_and_email", unique: true
    t.index ["company_id", "role"], name: "index_users_on_company_and_role"
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["first_name", "last_name"], name: "index_users_on_full_name"
    t.index ["last_login_at"], name: "index_users_on_last_login_at"
    t.index ["role"], name: "index_users_on_role"
    t.index ["settings"], name: "index_users_on_settings", using: :gin
    t.check_constraint "email::text ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+.[A-Za-z]{2,}$'::text", name: "users_email_format_check"
    t.check_constraint "length(TRIM(BOTH FROM first_name)) > 0", name: "users_first_name_not_empty_check"
    t.check_constraint "length(TRIM(BOTH FROM last_name)) > 0", name: "users_last_name_not_empty_check"
    t.check_constraint "role = ANY (ARRAY[0, 1, 2, 3])", name: "users_role_check"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "applications", "candidates"
  add_foreign_key "applications", "companies"
  add_foreign_key "applications", "jobs"
  add_foreign_key "applications", "users", column: "stage_changed_by_id"
  add_foreign_key "interviews", "applications"
  add_foreign_key "interviews", "users", column: "interviewer_id"
  add_foreign_key "interviews", "users", column: "scheduled_by_id"
  add_foreign_key "jobs", "companies"
  add_foreign_key "jobs", "users", column: "hiring_manager_id"
  add_foreign_key "users", "companies"
end
