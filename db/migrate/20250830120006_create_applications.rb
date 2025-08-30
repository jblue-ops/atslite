# frozen_string_literal: true

class CreateApplications < ActiveRecord::Migration[7.2]
  def change
    create_table :applications, id: :uuid do |t|
      # Foreign key relationships
      t.references :company, null: false, foreign_key: true, type: :uuid, index: true
      t.references :job, null: false, foreign_key: true, type: :uuid, index: true
      t.references :candidate, null: false, foreign_key: true, type: :uuid, index: true
      t.references :stage_changed_by, null: true, foreign_key: { to_table: :users }, type: :uuid, index: true

      # Application pipeline status
      t.string :status, null: false, default: 'applied'
      t.string :source, limit: 100
      
      # Timeline tracking
      t.datetime :applied_at, null: false
      t.datetime :stage_changed_at
      t.datetime :rejected_at
      
      # Application content
      t.text :cover_letter
      t.text :notes # Internal recruiter notes
      
      # Evaluation
      t.integer :rating # 1-5 scale
      t.string :rejection_reason, limit: 255
      
      # Compensation
      t.integer :salary_offered # In cents for precision
      
      # Flexible metadata storage
      t.jsonb :metadata, null: false, default: {}

      t.timestamps null: false
    end

    # Comprehensive indexing for performance
    add_index :applications, :status
    add_index :applications, :applied_at
    add_index :applications, :stage_changed_at
    add_index :applications, :rejected_at
    add_index :applications, :rating
    add_index :applications, :salary_offered
    add_index :applications, :metadata, using: :gin
    
    # Composite indexes for common queries
    add_index :applications, [:company_id, :status], name: 'index_applications_on_company_and_status'
    add_index :applications, [:job_id, :status], name: 'index_applications_on_job_and_status'
    add_index :applications, [:candidate_id, :status], name: 'index_applications_on_candidate_and_status'
    add_index :applications, [:company_id, :applied_at], name: 'index_applications_on_company_and_applied_at'
    add_index :applications, [:job_id, :applied_at], name: 'index_applications_on_job_and_applied_at'
    
    # Unique constraint - one application per candidate per job
    add_index :applications, [:candidate_id, :job_id], unique: true, 
              name: 'index_applications_on_candidate_and_job_unique'

    # Database constraints for data integrity
    execute <<-SQL
      ALTER TABLE applications
      ADD CONSTRAINT applications_status_check
      CHECK (status IN (
        'applied', 'screening', 'phone_interview', 'technical_interview',
        'final_interview', 'offer', 'accepted', 'rejected', 'withdrawn'
      ));
    SQL

    execute <<-SQL
      ALTER TABLE applications
      ADD CONSTRAINT applications_rating_check
      CHECK (rating IS NULL OR (rating >= 1 AND rating <= 5));
    SQL

    execute <<-SQL
      ALTER TABLE applications
      ADD CONSTRAINT applications_salary_offered_check
      CHECK (salary_offered IS NULL OR salary_offered >= 0);
    SQL

    # Ensure applied_at is set
    execute <<-SQL
      ALTER TABLE applications
      ADD CONSTRAINT applications_applied_at_not_null_check
      CHECK (applied_at IS NOT NULL);
    SQL

    # Ensure rejection data consistency
    execute <<-SQL
      ALTER TABLE applications
      ADD CONSTRAINT applications_rejection_consistency_check
      CHECK (
        (status = 'rejected' AND rejected_at IS NOT NULL) OR
        (status != 'rejected' AND rejected_at IS NULL)
      );
    SQL
  end
end