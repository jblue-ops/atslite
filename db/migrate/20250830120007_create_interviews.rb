# frozen_string_literal: true

class CreateInterviews < ActiveRecord::Migration[7.2]
  def change
    create_table :interviews, id: :uuid do |t|
      # Foreign key relationships
      t.references :application, null: false, foreign_key: true, type: :uuid, index: true
      t.references :interviewer, null: false, foreign_key: { to_table: :users }, type: :uuid, index: true
      t.references :scheduled_by, null: true, foreign_key: { to_table: :users }, type: :uuid, index: true

      # Interview configuration
      t.string :interview_type, null: false
      t.string :status, null: false, default: 'scheduled'
      
      # Scheduling details
      t.datetime :scheduled_at, null: false
      t.integer :duration_minutes, default: 60
      t.string :location, limit: 255 # For onsite interviews
      t.string :video_link, limit: 500 # For remote interviews
      t.string :calendar_event_id, limit: 100 # For calendar integration
      
      # Interview outcome
      t.text :feedback
      t.integer :rating # 1-5 scale
      t.string :decision # strong_yes, yes, maybe, no, strong_no
      t.datetime :completed_at
      t.text :notes # Additional notes
      
      # Flexible metadata storage
      t.jsonb :metadata, null: false, default: {}

      t.timestamps null: false
    end

    # Comprehensive indexing for performance
    add_index :interviews, :interview_type
    add_index :interviews, :status
    add_index :interviews, :scheduled_at
    add_index :interviews, :completed_at
    add_index :interviews, :rating
    add_index :interviews, :decision
    add_index :interviews, :duration_minutes
    add_index :interviews, :metadata, using: :gin
    
    # Composite indexes for common queries
    add_index :interviews, [:application_id, :status], name: 'index_interviews_on_application_and_status'
    add_index :interviews, [:application_id, :scheduled_at], name: 'index_interviews_on_application_and_scheduled_at'
    add_index :interviews, [:interviewer_id, :status], name: 'index_interviews_on_interviewer_and_status'
    add_index :interviews, [:interviewer_id, :scheduled_at], name: 'index_interviews_on_interviewer_and_scheduled_at'
    add_index :interviews, [:scheduled_by_id, :scheduled_at], name: 'index_interviews_on_scheduled_by_and_date'
    add_index :interviews, [:status, :scheduled_at], name: 'index_interviews_on_status_and_scheduled_at'
    
    # For finding interviews in date ranges
    add_index :interviews, [:scheduled_at, :status], name: 'index_interviews_on_date_and_status'

    # Database constraints for data integrity
    execute <<-SQL
      ALTER TABLE interviews
      ADD CONSTRAINT interviews_interview_type_check
      CHECK (interview_type IN (
        'phone', 'video', 'onsite', 'technical', 'behavioral', 'panel'
      ));
    SQL

    execute <<-SQL
      ALTER TABLE interviews
      ADD CONSTRAINT interviews_status_check
      CHECK (status IN (
        'scheduled', 'confirmed', 'completed', 'cancelled', 'no_show'
      ));
    SQL

    execute <<-SQL
      ALTER TABLE interviews
      ADD CONSTRAINT interviews_decision_check
      CHECK (decision IS NULL OR decision IN (
        'strong_yes', 'yes', 'maybe', 'no', 'strong_no'
      ));
    SQL

    execute <<-SQL
      ALTER TABLE interviews
      ADD CONSTRAINT interviews_rating_check
      CHECK (rating IS NULL OR (rating >= 1 AND rating <= 5));
    SQL

    execute <<-SQL
      ALTER TABLE interviews
      ADD CONSTRAINT interviews_duration_check
      CHECK (duration_minutes IS NULL OR duration_minutes > 0);
    SQL

    # Ensure completed interviews have completion data
    execute <<-SQL
      ALTER TABLE interviews
      ADD CONSTRAINT interviews_completion_consistency_check
      CHECK (
        (status = 'completed' AND completed_at IS NOT NULL) OR
        (status != 'completed' AND completed_at IS NULL)
      );
    SQL

    # Ensure scheduled_at is in the future when created (will be handled by application logic)
    # But we can ensure it's not null
    execute <<-SQL
      ALTER TABLE interviews
      ADD CONSTRAINT interviews_scheduled_at_not_null_check
      CHECK (scheduled_at IS NOT NULL);
    SQL
  end
end