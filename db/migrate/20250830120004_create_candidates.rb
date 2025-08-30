# frozen_string_literal: true

class CreateCandidates < ActiveRecord::Migration[7.2]
  def change
    create_table :candidates, id: :uuid do |t|
      # Personal information
      t.string :email, null: false
      t.string :first_name, null: false, limit: 50
      t.string :last_name, null: false, limit: 100
      t.string :phone
      t.string :location, limit: 100
      
      # Professional URLs
      t.string :linkedin_url
      t.string :portfolio_url
      t.string :github_url
      
      # Professional information
      t.text :bio, limit: 2000
      t.string :current_job_title, limit: 100
      t.string :current_company, limit: 100
      t.integer :years_of_experience
      
      # Salary information
      t.decimal :current_salary, precision: 12, scale: 2
      t.string :current_salary_currency, limit: 3, default: 'USD'
      t.decimal :desired_salary_min, precision: 12, scale: 2
      t.decimal :desired_salary_max, precision: 12, scale: 2
      t.string :desired_salary_currency, limit: 3, default: 'USD'
      
      # Work authorization and availability
      t.string :work_authorization
      t.string :notice_period
      
      # Preferences and availability
      t.boolean :open_to_remote, null: false, default: false
      t.boolean :willing_to_relocate, null: false, default: false
      t.boolean :available_for_interview, null: false, default: true
      
      # Resume and documents
      t.string :resume_url
      t.text :resume_text
      
      # JSON fields for arrays/complex data
      t.jsonb :skills, null: false, default: []
      t.jsonb :languages, null: false, default: {}
      t.jsonb :certifications, null: false, default: []
      t.jsonb :preferred_work_types, null: false, default: []
      t.jsonb :preferred_locations, null: false, default: []
      t.jsonb :additional_documents, null: false, default: []
      
      # Privacy and consent tracking
      t.boolean :marketing_consent, null: false, default: false
      t.datetime :marketing_consent_at
      t.boolean :data_processing_consent, null: false, default: false
      t.datetime :data_processing_consent_at
      
      # Activity tracking
      t.datetime :last_activity_at
      
      # GDPR compliance
      t.datetime :gdpr_delete_after
      
      # Soft delete
      t.datetime :deleted_at
      
      t.timestamps null: false
    end

    # Unique constraint on email
    add_index :candidates, :email, unique: true
    
    # Performance indexes for common queries
    add_index :candidates, :first_name
    add_index :candidates, :last_name
    add_index :candidates, [:first_name, :last_name], name: 'index_candidates_on_full_name'
    add_index :candidates, :location
    add_index :candidates, :current_job_title
    add_index :candidates, :current_company
    add_index :candidates, :years_of_experience
    add_index :candidates, :current_salary
    add_index :candidates, :desired_salary_min
    add_index :candidates, :desired_salary_max
    add_index :candidates, :work_authorization
    add_index :candidates, :notice_period
    add_index :candidates, :open_to_remote
    add_index :candidates, :willing_to_relocate
    add_index :candidates, :available_for_interview
    # marketing_consent and data_processing_consent indexes are created as composites below
    # add_index :candidates, :marketing_consent
    # add_index :candidates, :data_processing_consent
    add_index :candidates, :last_activity_at
    add_index :candidates, :gdpr_delete_after
    add_index :candidates, :deleted_at
    add_index :candidates, :created_at
    
    # Composite indexes for common filter combinations
    add_index :candidates, [:work_authorization, :years_of_experience], name: 'index_candidates_on_auth_and_experience'
    add_index :candidates, [:open_to_remote, :willing_to_relocate], name: 'index_candidates_on_remote_and_relocate'
    add_index :candidates, [:desired_salary_min, :desired_salary_max], name: 'index_candidates_on_desired_salary_range'
    add_index :candidates, [:marketing_consent, :marketing_consent_at], name: 'index_candidates_on_marketing_consent'
    add_index :candidates, [:data_processing_consent, :data_processing_consent_at], name: 'index_candidates_on_data_consent'
    add_index :candidates, [:available_for_interview, :deleted_at], name: 'index_candidates_on_available_and_active'
    add_index :candidates, [:last_activity_at, :deleted_at], name: 'index_candidates_on_activity_and_active'
    
    # GIN indexes for JSONB fields and text search
    add_index :candidates, :skills, using: :gin
    add_index :candidates, :languages, using: :gin
    add_index :candidates, :certifications, using: :gin
    add_index :candidates, :preferred_work_types, using: :gin
    add_index :candidates, :preferred_locations, using: :gin
    add_index :candidates, :additional_documents, using: :gin
    add_index :candidates, :bio, using: :gin, opclass: :gin_trgm_ops
    add_index :candidates, :resume_text, using: :gin, opclass: :gin_trgm_ops
    
    # Add check constraints for enum fields
    execute <<-SQL
      ALTER TABLE candidates
      ADD CONSTRAINT candidates_work_authorization_check
      CHECK (work_authorization IS NULL OR work_authorization IN ('citizen', 'permanent_resident', 'work_visa', 'student_visa', 'needs_sponsorship'));
    SQL

    execute <<-SQL
      ALTER TABLE candidates
      ADD CONSTRAINT candidates_notice_period_check
      CHECK (notice_period IS NULL OR notice_period IN ('immediate', 'two_weeks', 'one_month', 'two_months', 'three_months', 'other'));
    SQL

    # Add check constraints for data validation
    execute <<-SQL
      ALTER TABLE candidates
      ADD CONSTRAINT candidates_email_format_check
      CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    SQL

    execute <<-SQL
      ALTER TABLE candidates
      ADD CONSTRAINT candidates_first_name_not_empty_check
      CHECK (length(trim(first_name)) > 0);
    SQL

    execute <<-SQL
      ALTER TABLE candidates
      ADD CONSTRAINT candidates_last_name_not_empty_check
      CHECK (length(trim(last_name)) > 0);
    SQL

    execute <<-SQL
      ALTER TABLE candidates
      ADD CONSTRAINT candidates_phone_format_check
      CHECK (phone IS NULL OR phone ~ '^[\\+\\d\\s\\-\\(\\)\\.]+$');
    SQL

    execute <<-SQL
      ALTER TABLE candidates
      ADD CONSTRAINT candidates_linkedin_format_check
      CHECK (linkedin_url IS NULL OR linkedin_url ~* '^https?://(www\\.)?linkedin\\.com/in/[\\w\\-]+/?$');
    SQL

    execute <<-SQL
      ALTER TABLE candidates
      ADD CONSTRAINT candidates_github_format_check
      CHECK (github_url IS NULL OR github_url ~* '^https?://(www\\.)?github\\.com/[\\w\\-]+/?$');
    SQL

    execute <<-SQL
      ALTER TABLE candidates
      ADD CONSTRAINT candidates_portfolio_url_format_check
      CHECK (portfolio_url IS NULL OR portfolio_url ~* '^https?://');
    SQL

    execute <<-SQL
      ALTER TABLE candidates
      ADD CONSTRAINT candidates_years_experience_check
      CHECK (years_of_experience IS NULL OR (years_of_experience >= 0 AND years_of_experience < 70));
    SQL

    execute <<-SQL
      ALTER TABLE candidates
      ADD CONSTRAINT candidates_salary_positive_check
      CHECK (
        (current_salary IS NULL OR current_salary >= 0) AND
        (desired_salary_min IS NULL OR desired_salary_min >= 0) AND
        (desired_salary_max IS NULL OR desired_salary_max >= 0)
      );
    SQL

    execute <<-SQL
      ALTER TABLE candidates
      ADD CONSTRAINT candidates_desired_salary_range_check
      CHECK (desired_salary_min IS NULL OR desired_salary_max IS NULL OR desired_salary_max >= desired_salary_min);
    SQL

    execute <<-SQL
      ALTER TABLE candidates
      ADD CONSTRAINT candidates_currency_format_check
      CHECK (
        (current_salary_currency IS NULL OR length(current_salary_currency) = 3) AND
        (desired_salary_currency IS NULL OR length(desired_salary_currency) = 3)
      );
    SQL

    execute <<-SQL
      ALTER TABLE candidates
      ADD CONSTRAINT candidates_bio_length_check
      CHECK (bio IS NULL OR length(bio) <= 2000);
    SQL

    execute <<-SQL
      ALTER TABLE candidates
      ADD CONSTRAINT candidates_marketing_consent_at_check
      CHECK ((marketing_consent = false AND marketing_consent_at IS NULL) OR (marketing_consent = true AND marketing_consent_at IS NOT NULL));
    SQL

    execute <<-SQL
      ALTER TABLE candidates
      ADD CONSTRAINT candidates_data_processing_consent_at_check
      CHECK ((data_processing_consent = false AND data_processing_consent_at IS NULL) OR (data_processing_consent = true AND data_processing_consent_at IS NOT NULL));
    SQL

    execute <<-SQL
      ALTER TABLE candidates
      ADD CONSTRAINT candidates_gdpr_delete_future_check
      CHECK (gdpr_delete_after IS NULL OR gdpr_delete_after > created_at);
    SQL
  end
end