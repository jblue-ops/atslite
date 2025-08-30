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

ActiveRecord::Schema[8.0].define(version: 2025_08_30_003729) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "uuid-ossp"

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

  create_table "activities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.uuid "actor_id"
    t.string "trackable_type", null: false
    t.uuid "trackable_id", null: false
    t.string "action", null: false
    t.string "category", null: false
    t.text "description"
    t.json "changes", default: {}
    t.json "metadata", default: {}
    t.string "importance", default: "normal"
    t.boolean "visible_to_candidate", default: false
    t.string "ip_address"
    t.string "user_agent"
    t.string "source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_activities_on_action"
    t.index ["actor_id", "created_at"], name: "index_activities_on_actor_id_and_created_at"
    t.index ["actor_id"], name: "index_activities_on_actor_id"
    t.index ["category"], name: "index_activities_on_category"
    t.index ["created_at"], name: "index_activities_on_created_at"
    t.index ["importance"], name: "index_activities_on_importance"
    t.index ["organization_id", "created_at"], name: "index_activities_on_organization_id_and_created_at"
    t.index ["organization_id"], name: "index_activities_on_organization_id"
    t.index ["trackable_type", "trackable_id", "created_at"], name: "idx_on_trackable_type_trackable_id_created_at_85c0aafe3a"
    t.index ["trackable_type", "trackable_id"], name: "index_activities_on_trackable"
    t.index ["visible_to_candidate"], name: "index_activities_on_visible_to_candidate"
  end

  create_table "applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "job_id", null: false
    t.uuid "candidate_id", null: false
    t.uuid "assigned_recruiter_id"
    t.uuid "referrer_id"
    t.string "status", default: "applied", null: false
    t.string "current_stage", default: "applied", null: false
    t.integer "stage_order", default: 1
    t.datetime "stage_changed_at", default: -> { "CURRENT_TIMESTAMP" }
    t.json "stage_history", default: []
    t.string "source", null: false
    t.string "source_details"
    t.string "application_method"
    t.text "cover_letter"
    t.json "questionnaire_responses", default: {}
    t.json "screening_questions", default: {}
    t.string "application_resume_filename"
    t.string "application_resume_url"
    t.text "application_resume_text"
    t.decimal "overall_score", precision: 4, scale: 2
    t.integer "recruiter_rating"
    t.integer "hiring_manager_rating"
    t.json "skill_ratings", default: {}
    t.text "rating_notes"
    t.integer "email_opens", default: 0
    t.integer "email_clicks", default: 0
    t.datetime "last_email_sent_at"
    t.datetime "last_viewed_job_at"
    t.datetime "last_response_at"
    t.decimal "offered_salary", precision: 12, scale: 2
    t.string "offered_salary_currency", default: "USD"
    t.json "offer_details", default: {}
    t.datetime "offer_sent_at"
    t.datetime "offer_expires_at"
    t.datetime "offer_accepted_at"
    t.datetime "offer_declined_at"
    t.text "decline_reason"
    t.boolean "starred", default: false
    t.boolean "flagged", default: false
    t.text "flag_reason"
    t.json "tags", default: []
    t.boolean "gdpr_consent", default: true
    t.datetime "gdpr_consent_at"
    t.boolean "background_check_required", default: false
    t.boolean "background_check_completed", default: false
    t.datetime "background_check_completed_at"
    t.datetime "withdrawn_at"
    t.text "withdrawal_reason"
    t.datetime "rejected_at"
    t.text "rejection_reason"
    t.datetime "hired_at"
    t.datetime "start_date"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_recruiter_id", "status"], name: "index_applications_on_assigned_recruiter_id_and_status"
    t.index ["assigned_recruiter_id"], name: "index_applications_on_assigned_recruiter_id"
    t.index ["candidate_id"], name: "index_applications_on_candidate_id"
    t.index ["current_stage"], name: "index_applications_on_current_stage"
    t.index ["deleted_at"], name: "index_applications_on_deleted_at"
    t.index ["flagged"], name: "index_applications_on_flagged"
    t.index ["hired_at"], name: "index_applications_on_hired_at"
    t.index ["job_id", "candidate_id"], name: "index_applications_on_job_id_and_candidate_id", unique: true
    t.index ["job_id", "current_stage"], name: "index_applications_on_job_id_and_current_stage"
    t.index ["job_id", "status"], name: "index_applications_on_job_id_and_status"
    t.index ["job_id"], name: "index_applications_on_job_id"
    t.index ["offer_sent_at"], name: "index_applications_on_offer_sent_at"
    t.index ["overall_score"], name: "index_applications_on_overall_score"
    t.index ["referrer_id"], name: "index_applications_on_referrer_id"
    t.index ["source"], name: "index_applications_on_source"
    t.index ["stage_changed_at"], name: "index_applications_on_stage_changed_at"
    t.index ["starred"], name: "index_applications_on_starred"
    t.index ["status"], name: "index_applications_on_status"
  end

  create_table "candidates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone"
    t.string "location"
    t.string "time_zone"
    t.text "address"
    t.string "linkedin_url"
    t.string "portfolio_url"
    t.string "github_url"
    t.text "bio"
    t.string "current_job_title"
    t.string "current_company"
    t.decimal "current_salary", precision: 12, scale: 2
    t.string "current_salary_currency", default: "USD"
    t.decimal "desired_salary_min", precision: 12, scale: 2
    t.decimal "desired_salary_max", precision: 12, scale: 2
    t.string "desired_salary_currency", default: "USD"
    t.string "notice_period"
    t.boolean "open_to_remote", default: false
    t.boolean "willing_to_relocate", default: false
    t.string "work_authorization"
    t.json "skills", default: []
    t.integer "years_of_experience", default: 0
    t.json "languages", default: []
    t.json "certifications", default: []
    t.string "resume_filename"
    t.string "resume_content_type"
    t.integer "resume_file_size"
    t.text "resume_url"
    t.text "resume_text"
    t.json "additional_documents", default: []
    t.json "preferred_work_types", default: []
    t.json "preferred_locations", default: []
    t.boolean "available_for_interview", default: true
    t.text "availability_notes"
    t.boolean "marketing_consent", default: false
    t.datetime "marketing_consent_at"
    t.boolean "data_processing_consent", default: true, null: false
    t.datetime "data_processing_consent_at"
    t.datetime "gdpr_delete_after"
    t.datetime "last_activity_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["available_for_interview"], name: "index_candidates_on_available_for_interview"
    t.index ["current_job_title"], name: "index_candidates_on_current_job_title"
    t.index ["deleted_at"], name: "index_candidates_on_deleted_at"
    t.index ["email"], name: "index_candidates_on_email", unique: true
    t.index ["first_name", "last_name"], name: "index_candidates_on_first_name_and_last_name"
    t.index ["gdpr_delete_after"], name: "index_candidates_on_gdpr_delete_after"
    t.index ["last_activity_at"], name: "index_candidates_on_last_activity_at"
    t.index ["location"], name: "index_candidates_on_location"
    t.index ["open_to_remote"], name: "index_candidates_on_open_to_remote"
    t.index ["work_authorization"], name: "index_candidates_on_work_authorization"
    t.index ["years_of_experience"], name: "index_candidates_on_years_of_experience"
  end

  create_table "communications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.uuid "application_id", null: false
    t.uuid "sender_id"
    t.string "communication_type", null: false
    t.string "direction", null: false
    t.string "status", default: "sent", null: false
    t.string "subject"
    t.text "body_html"
    t.text "body_text"
    t.json "attachments", default: []
    t.json "to_addresses", default: []
    t.json "cc_addresses", default: []
    t.json "bcc_addresses", default: []
    t.string "from_address"
    t.string "reply_to_address"
    t.string "template_name"
    t.json "template_variables", default: {}
    t.boolean "automated", default: false
    t.string "automation_trigger"
    t.datetime "sent_at"
    t.datetime "delivered_at"
    t.datetime "opened_at"
    t.datetime "clicked_at"
    t.integer "open_count", default: 0
    t.integer "click_count", default: 0
    t.json "click_urls", default: []
    t.string "phone_number"
    t.integer "call_duration_seconds"
    t.string "call_outcome"
    t.text "call_notes"
    t.string "external_id"
    t.string "external_service"
    t.json "external_metadata", default: {}
    t.string "thread_id"
    t.uuid "in_reply_to_id"
    t.datetime "scheduled_for"
    t.boolean "is_scheduled", default: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id", "communication_type"], name: "index_communications_on_application_id_and_communication_type"
    t.index ["application_id", "created_at"], name: "index_communications_on_application_id_and_created_at"
    t.index ["application_id"], name: "index_communications_on_application_id"
    t.index ["automated"], name: "index_communications_on_automated"
    t.index ["communication_type"], name: "index_communications_on_communication_type"
    t.index ["deleted_at"], name: "index_communications_on_deleted_at"
    t.index ["direction"], name: "index_communications_on_direction"
    t.index ["in_reply_to_id"], name: "index_communications_on_in_reply_to_id"
    t.index ["opened_at"], name: "index_communications_on_opened_at"
    t.index ["organization_id", "sent_at"], name: "index_communications_on_organization_id_and_sent_at"
    t.index ["organization_id"], name: "index_communications_on_organization_id"
    t.index ["scheduled_for"], name: "index_communications_on_scheduled_for"
    t.index ["sender_id"], name: "index_communications_on_sender_id"
    t.index ["sent_at"], name: "index_communications_on_sent_at"
    t.index ["status"], name: "index_communications_on_status"
    t.index ["template_name"], name: "index_communications_on_template_name"
    t.index ["thread_id"], name: "index_communications_on_thread_id"
  end

  create_table "departments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.uuid "parent_department_id"
    t.string "name", null: false
    t.text "description"
    t.string "code"
    t.boolean "active", default: true, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_departments_on_active"
    t.index ["deleted_at"], name: "index_departments_on_deleted_at"
    t.index ["organization_id", "code"], name: "index_departments_on_organization_id_and_code", unique: true
    t.index ["organization_id", "name"], name: "index_departments_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_departments_on_organization_id"
    t.index ["parent_department_id"], name: "index_departments_on_parent_department_id"
  end

  create_table "interview_participants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "interview_id", null: false
    t.uuid "user_id", null: false
    t.string "role", null: false
    t.boolean "required", default: true
    t.string "response_status", default: "pending"
    t.datetime "responded_at"
    t.text "response_notes"
    t.text "feedback"
    t.integer "rating"
    t.json "skill_ratings", default: {}
    t.boolean "recommend_hire"
    t.text "recommendation_notes"
    t.boolean "feedback_submitted", default: false
    t.datetime "feedback_submitted_at"
    t.datetime "joined_at"
    t.datetime "left_at"
    t.integer "participation_minutes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feedback_submitted"], name: "index_interview_participants_on_feedback_submitted"
    t.index ["interview_id", "user_id"], name: "index_interview_participants_on_interview_id_and_user_id", unique: true
    t.index ["interview_id"], name: "index_interview_participants_on_interview_id"
    t.index ["rating"], name: "index_interview_participants_on_rating"
    t.index ["required"], name: "index_interview_participants_on_required"
    t.index ["response_status"], name: "index_interview_participants_on_response_status"
    t.index ["role"], name: "index_interview_participants_on_role"
    t.index ["user_id"], name: "index_interview_participants_on_user_id"
  end

  create_table "interviews", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "application_id", null: false
    t.uuid "organizer_id", null: false
    t.uuid "primary_interviewer_id"
    t.string "title", null: false
    t.text "description"
    t.string "interview_type", null: false
    t.string "stage", null: false
    t.string "status", default: "scheduled", null: false
    t.datetime "scheduled_start_time", null: false
    t.datetime "scheduled_end_time", null: false
    t.datetime "actual_start_time"
    t.datetime "actual_end_time"
    t.integer "duration_minutes", null: false
    t.integer "actual_duration_minutes"
    t.string "location_type", null: false
    t.string "meeting_url"
    t.text "meeting_details"
    t.string "location_address"
    t.json "technical_requirements", default: {}
    t.json "interview_kit", default: {}
    t.text "interviewer_notes"
    t.text "candidate_instructions"
    t.json "focus_areas", default: []
    t.text "interview_notes"
    t.text "interviewer_feedback"
    t.integer "overall_rating"
    t.json "skill_assessments", default: {}
    t.json "scoring_rubric", default: {}
    t.boolean "recommend_hire", default: false
    t.text "recommendation_notes"
    t.text "next_steps"
    t.boolean "requires_followup", default: false
    t.datetime "followup_due_date"
    t.text "followup_notes"
    t.boolean "reminder_sent", default: false
    t.datetime "reminder_sent_at"
    t.boolean "confirmation_received", default: false
    t.datetime "confirmation_received_at"
    t.text "candidate_preparation_notes"
    t.json "attendee_emails", default: []
    t.string "calendar_event_id"
    t.boolean "feedback_submitted", default: false
    t.datetime "feedback_submitted_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id", "stage"], name: "index_interviews_on_application_id_and_stage"
    t.index ["application_id"], name: "index_interviews_on_application_id"
    t.index ["deleted_at"], name: "index_interviews_on_deleted_at"
    t.index ["feedback_submitted"], name: "index_interviews_on_feedback_submitted"
    t.index ["interview_type"], name: "index_interviews_on_interview_type"
    t.index ["location_type"], name: "index_interviews_on_location_type"
    t.index ["organizer_id"], name: "index_interviews_on_organizer_id"
    t.index ["overall_rating"], name: "index_interviews_on_overall_rating"
    t.index ["primary_interviewer_id", "status"], name: "index_interviews_on_primary_interviewer_id_and_status"
    t.index ["primary_interviewer_id"], name: "index_interviews_on_primary_interviewer_id"
    t.index ["recommend_hire"], name: "index_interviews_on_recommend_hire"
    t.index ["scheduled_start_time", "status"], name: "index_interviews_on_scheduled_start_time_and_status"
    t.index ["scheduled_start_time"], name: "index_interviews_on_scheduled_start_time"
    t.index ["stage"], name: "index_interviews_on_stage"
    t.index ["status"], name: "index_interviews_on_status"
  end

  create_table "jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.uuid "department_id"
    t.uuid "hiring_manager_id"
    t.string "title", null: false
    t.text "description", null: false
    t.text "requirements"
    t.text "benefits"
    t.string "employment_type", null: false
    t.string "work_location_type", null: false
    t.string "location"
    t.string "experience_level"
    t.decimal "salary_min", precision: 12, scale: 2
    t.decimal "salary_max", precision: 12, scale: 2
    t.string "salary_currency", default: "USD"
    t.string "salary_period"
    t.string "status", default: "draft", null: false
    t.json "pipeline_stages", default: [{"name" => "Applied", "type" => "applied", "order" => 1}, {"name" => "Phone Screen", "type" => "phone_screen", "order" => 2}, {"name" => "Technical Interview", "type" => "technical", "order" => 3}, {"name" => "Final Interview", "type" => "final", "order" => 4}, {"name" => "Offer", "type" => "offer", "order" => 5}, {"name" => "Hired", "type" => "hired", "order" => 6}], null: false
    t.datetime "posted_at"
    t.datetime "application_deadline"
    t.datetime "target_start_date"
    t.string "urgency"
    t.integer "openings_count", default: 1
    t.json "required_skills", default: []
    t.json "nice_to_have_skills", default: []
    t.string "referral_bonus_amount"
    t.boolean "confidential", default: false
    t.boolean "remote_work_eligible", default: false
    t.text "internal_notes"
    t.boolean "active", default: true, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_jobs_on_active"
    t.index ["application_deadline"], name: "index_jobs_on_application_deadline"
    t.index ["deleted_at"], name: "index_jobs_on_deleted_at"
    t.index ["department_id"], name: "index_jobs_on_department_id"
    t.index ["employment_type"], name: "index_jobs_on_employment_type"
    t.index ["experience_level"], name: "index_jobs_on_experience_level"
    t.index ["hiring_manager_id"], name: "index_jobs_on_hiring_manager_id"
    t.index ["organization_id", "department_id"], name: "index_jobs_on_organization_id_and_department_id"
    t.index ["organization_id", "status"], name: "index_jobs_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_jobs_on_organization_id"
    t.index ["posted_at"], name: "index_jobs_on_posted_at"
    t.index ["status"], name: "index_jobs_on_status"
    t.index ["title"], name: "index_jobs_on_title"
    t.index ["urgency"], name: "index_jobs_on_urgency"
    t.index ["work_location_type"], name: "index_jobs_on_work_location_type"
  end

  create_table "notes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.uuid "author_id", null: false
    t.string "notable_type", null: false
    t.uuid "notable_id", null: false
    t.text "content", null: false
    t.string "note_type", default: "general"
    t.string "visibility", default: "team"
    t.boolean "pinned", default: false
    t.string "importance", default: "normal"
    t.json "mentioned_user_ids", default: []
    t.boolean "notifications_sent", default: false
    t.boolean "requires_followup", default: false
    t.datetime "followup_due_date"
    t.boolean "followup_completed", default: false
    t.datetime "followup_completed_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id", "created_at"], name: "index_notes_on_author_id_and_created_at"
    t.index ["author_id"], name: "index_notes_on_author_id"
    t.index ["created_at"], name: "index_notes_on_created_at"
    t.index ["deleted_at"], name: "index_notes_on_deleted_at"
    t.index ["followup_due_date"], name: "index_notes_on_followup_due_date"
    t.index ["importance"], name: "index_notes_on_importance"
    t.index ["notable_type", "notable_id", "created_at"], name: "index_notes_on_notable_type_and_notable_id_and_created_at"
    t.index ["notable_type", "notable_id"], name: "index_notes_on_notable"
    t.index ["note_type"], name: "index_notes_on_note_type"
    t.index ["organization_id", "created_at"], name: "index_notes_on_organization_id_and_created_at"
    t.index ["organization_id"], name: "index_notes_on_organization_id"
    t.index ["pinned"], name: "index_notes_on_pinned"
    t.index ["requires_followup"], name: "index_notes_on_requires_followup"
    t.index ["visibility"], name: "index_notes_on_visibility"
  end

  create_table "organizations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "website_url"
    t.string "industry"
    t.string "size_category"
    t.string "logo_url"
    t.json "settings", default: {}
    t.boolean "active", default: true, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_organizations_on_active"
    t.index ["deleted_at"], name: "index_organizations_on_deleted_at"
    t.index ["industry"], name: "index_organizations_on_industry"
    t.index ["name"], name: "index_organizations_on_name"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organization_id", null: false
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "role", null: false
    t.string "phone"
    t.string "title"
    t.string "avatar_url"
    t.text "bio"
    t.string "time_zone", default: "UTC"
    t.string "password_digest"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.json "permissions", default: {}
    t.boolean "active", default: true, null: false
    t.boolean "email_verified", default: false, null: false
    t.datetime "email_verified_at"
    t.datetime "invited_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "remember_created_at"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.integer "invitations_count", default: 0
    t.uuid "invited_by_id"
    t.string "current_sign_in_ip"
    t.index ["active"], name: "index_users_on_active"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email"
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["organization_id", "email"], name: "index_users_on_organization_id_and_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activities", "organizations"
  add_foreign_key "activities", "users", column: "actor_id"
  add_foreign_key "applications", "candidates"
  add_foreign_key "applications", "jobs"
  add_foreign_key "applications", "users", column: "assigned_recruiter_id"
  add_foreign_key "applications", "users", column: "referrer_id"
  add_foreign_key "communications", "applications"
  add_foreign_key "communications", "communications", column: "in_reply_to_id"
  add_foreign_key "communications", "organizations"
  add_foreign_key "communications", "users", column: "sender_id"
  add_foreign_key "departments", "departments", column: "parent_department_id"
  add_foreign_key "departments", "organizations"
  add_foreign_key "interview_participants", "interviews"
  add_foreign_key "interview_participants", "users"
  add_foreign_key "interviews", "applications"
  add_foreign_key "interviews", "users", column: "organizer_id"
  add_foreign_key "interviews", "users", column: "primary_interviewer_id"
  add_foreign_key "jobs", "departments"
  add_foreign_key "jobs", "organizations"
  add_foreign_key "jobs", "users", column: "hiring_manager_id"
  add_foreign_key "notes", "organizations"
  add_foreign_key "notes", "users", column: "author_id"
  add_foreign_key "users", "organizations"
  add_foreign_key "users", "users", column: "invited_by_id"
end
