class ModifyJobsForPhase31 < ActiveRecord::Migration[8.0]
  def up
    # Add new fields
    add_column :jobs, :qualifications, :text
    add_column :jobs, :expires_at, :datetime
    add_column :jobs, :published_at, :datetime
    add_column :jobs, :application_count, :integer, default: 0
    add_column :jobs, :view_count, :integer, default: 0
    add_column :jobs, :settings, :jsonb, default: {}
    
    # Rename fields to match new model
    rename_column :jobs, :salary_min, :salary_range_min
    rename_column :jobs, :salary_max, :salary_range_max
    rename_column :jobs, :salary_currency, :currency
    rename_column :jobs, :remote_work_eligible, :remote_work_allowed
    rename_column :jobs, :posted_at, :legacy_posted_at
    
    # Update data types for salary fields to integer (cents)
    change_column :jobs, :salary_range_min, :integer
    change_column :jobs, :salary_range_max, :integer
    
    # Remove unused fields for this phase
    remove_column :jobs, :salary_period
    remove_column :jobs, :benefits
    remove_column :jobs, :pipeline_stages
    remove_column :jobs, :target_start_date
    remove_column :jobs, :urgency
    remove_column :jobs, :openings_count
    remove_column :jobs, :required_skills
    remove_column :jobs, :nice_to_have_skills
    remove_column :jobs, :referral_bonus_amount
    remove_column :jobs, :confidential
    remove_column :jobs, :internal_notes
    remove_column :jobs, :active
    remove_column :jobs, :deleted_at
    remove_column :jobs, :application_deadline
    remove_column :jobs, :work_location_type
    
    # Add missing indexes
    add_index :jobs, :published_at
    add_index :jobs, :expires_at
    add_index :jobs, :remote_work_allowed
    add_index :jobs, [:status, :published_at]
    add_index :jobs, :settings, using: :gin
    
    # Add check constraints
    add_check_constraint :jobs, "salary_range_min >= 0", name: "salary_range_min_positive"
    add_check_constraint :jobs, "salary_range_max >= salary_range_min", name: "salary_range_max_gte_min"
    add_check_constraint :jobs, "application_count >= 0", name: "application_count_positive"
    add_check_constraint :jobs, "view_count >= 0", name: "view_count_positive"
    add_check_constraint :jobs, "employment_type IN ('full_time', 'part_time', 'contract', 'temporary', 'internship')", 
                        name: "employment_type_valid"
    add_check_constraint :jobs, "status IN ('draft', 'published', 'closed', 'archived')", 
                        name: "status_valid"
    add_check_constraint :jobs, "experience_level IN ('entry', 'junior', 'mid', 'senior', 'lead', 'executive')", 
                        name: "experience_level_valid"
    
    # Update existing data
    execute <<~SQL
      UPDATE jobs SET 
        application_count = 0,
        view_count = 0,
        settings = '{}'::jsonb,
        published_at = legacy_posted_at
      WHERE published_at IS NULL;
    SQL
  end

  def down
    # This migration is not easily reversible due to data loss
    raise ActiveRecord::IrreversibleMigration
  end
end
