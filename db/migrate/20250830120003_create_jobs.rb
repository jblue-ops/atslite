# frozen_string_literal: true

class CreateJobs < ActiveRecord::Migration[7.2]
  def change
    create_table :jobs, id: :uuid do |t|
      # Basic job information
      t.string :title, null: false
      t.text :description
      t.text :requirements
      
      # References to other models
      t.references :company, null: false, foreign_key: true, type: :uuid, index: true
      t.string :department  # Simple string field instead of foreign key
      t.references :hiring_manager, null: true, foreign_key: { to_table: :users }, type: :uuid, index: true
      
      # Employment details
      t.string :employment_type, null: false
      t.string :experience_level, null: false
      t.string :work_location_type, null: false
      t.string :location, limit: 100
      
      # Salary information
      t.decimal :salary_min, precision: 12, scale: 2
      t.decimal :salary_max, precision: 12, scale: 2
      t.string :salary_currency, limit: 3
      t.string :salary_period
      
      # Job status and visibility
      t.string :status, null: false, default: 'draft'
      t.boolean :active, null: false, default: true
      t.boolean :confidential, null: false, default: false
      t.boolean :remote_work_eligible, null: false, default: false
      
      # Job posting details
      t.datetime :posted_at
      t.datetime :application_deadline
      t.datetime :target_start_date
      t.string :urgency
      t.integer :openings_count, default: 1
      
      # Additional information
      t.string :referral_bonus_amount, limit: 50
      t.text :benefits
      t.text :company_overview
      
      # JSON fields for arrays/complex data
      t.jsonb :required_skills, null: false, default: []
      t.jsonb :nice_to_have_skills, null: false, default: []
      t.jsonb :pipeline_stages, null: false, default: []
      
      # Soft delete
      t.datetime :deleted_at
      
      t.timestamps null: false
    end

    # Performance indexes for common queries
    add_index :jobs, :title
    # company_id and hiring_manager_id indexes are automatically created by foreign key constraints
    add_index :jobs, :department  # This is now a string field
    add_index :jobs, :employment_type
    add_index :jobs, :experience_level
    add_index :jobs, :work_location_type
    add_index :jobs, :status
    add_index :jobs, :active
    add_index :jobs, :confidential
    add_index :jobs, :remote_work_eligible
    add_index :jobs, :posted_at
    add_index :jobs, :application_deadline
    add_index :jobs, :urgency
    add_index :jobs, :deleted_at
    add_index :jobs, :location
    add_index :jobs, :salary_min
    add_index :jobs, :salary_max
    add_index :jobs, :salary_currency
    
    # Composite indexes for common filter combinations
    add_index :jobs, [:company_id, :status], name: 'index_jobs_on_company_and_status'
    add_index :jobs, [:active, :deleted_at], name: 'index_jobs_on_active_and_not_deleted'
    add_index :jobs, [:status, :posted_at], name: 'index_jobs_on_status_and_posted_date'
    add_index :jobs, [:employment_type, :experience_level], name: 'index_jobs_on_employment_and_experience'
    add_index :jobs, [:work_location_type, :remote_work_eligible], name: 'index_jobs_on_location_type_and_remote'
    add_index :jobs, [:salary_min, :salary_max, :salary_currency], name: 'index_jobs_on_salary_range'
    
    # GIN indexes for JSONB fields and text search
    add_index :jobs, :required_skills, using: :gin
    add_index :jobs, :nice_to_have_skills, using: :gin
    add_index :jobs, :pipeline_stages, using: :gin
    add_index :jobs, :description, using: :gin, opclass: :gin_trgm_ops
    add_index :jobs, :requirements, using: :gin, opclass: :gin_trgm_ops

    # Add check constraints for enum fields
    execute <<-SQL
      ALTER TABLE jobs
      ADD CONSTRAINT jobs_employment_type_check
      CHECK (employment_type IN ('full_time', 'part_time', 'contract', 'internship', 'temporary'));
    SQL

    execute <<-SQL
      ALTER TABLE jobs
      ADD CONSTRAINT jobs_experience_level_check
      CHECK (experience_level IN ('entry', 'mid', 'senior', 'executive'));
    SQL

    execute <<-SQL
      ALTER TABLE jobs
      ADD CONSTRAINT jobs_status_check
      CHECK (status IN ('draft', 'published', 'paused', 'closed', 'archived'));
    SQL

    execute <<-SQL
      ALTER TABLE jobs
      ADD CONSTRAINT jobs_work_location_type_check
      CHECK (work_location_type IN ('on_site', 'hybrid', 'remote'));
    SQL

    execute <<-SQL
      ALTER TABLE jobs
      ADD CONSTRAINT jobs_urgency_check
      CHECK (urgency IS NULL OR urgency IN ('low', 'medium', 'high', 'urgent'));
    SQL

    execute <<-SQL
      ALTER TABLE jobs
      ADD CONSTRAINT jobs_salary_period_check
      CHECK (salary_period IS NULL OR salary_period IN ('hourly', 'daily', 'weekly', 'monthly', 'annually'));
    SQL

    # Add check constraints for data validation
    execute <<-SQL
      ALTER TABLE jobs
      ADD CONSTRAINT jobs_title_not_empty_check
      CHECK (length(trim(title)) >= 3);
    SQL

    execute <<-SQL
      ALTER TABLE jobs
      ADD CONSTRAINT jobs_salary_range_check
      CHECK (salary_min IS NULL OR salary_max IS NULL OR salary_max >= salary_min);
    SQL

    execute <<-SQL
      ALTER TABLE jobs
      ADD CONSTRAINT jobs_salary_positive_check
      CHECK ((salary_min IS NULL OR salary_min >= 0) AND (salary_max IS NULL OR salary_max >= 0));
    SQL

    execute <<-SQL
      ALTER TABLE jobs
      ADD CONSTRAINT jobs_openings_count_positive_check
      CHECK (openings_count IS NULL OR openings_count > 0);
    SQL

    execute <<-SQL
      ALTER TABLE jobs
      ADD CONSTRAINT jobs_currency_format_check
      CHECK (salary_currency IS NULL OR length(salary_currency) = 3);
    SQL

    execute <<-SQL
      ALTER TABLE jobs
      ADD CONSTRAINT jobs_posted_before_deadline_check
      CHECK (posted_at IS NULL OR application_deadline IS NULL OR application_deadline > posted_at);
    SQL

    execute <<-SQL
      ALTER TABLE jobs
      ADD CONSTRAINT jobs_posted_before_start_check
      CHECK (posted_at IS NULL OR target_start_date IS NULL OR target_start_date > posted_at);
    SQL

    # Add constraint to ensure published jobs have posted_at
    execute <<-SQL
      ALTER TABLE jobs
      ADD CONSTRAINT jobs_published_has_posted_at_check
      CHECK (status != 'published' OR posted_at IS NOT NULL);
    SQL
  end
end