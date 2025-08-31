class CreateJobTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :job_templates, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      # Template metadata
      t.string :name, null: false
      t.text :description
      t.string :category, null: false
      t.text :tags # Comma-separated tags for better organization
      t.boolean :is_active, default: true, null: false
      t.boolean :is_default, default: false, null: false
      
      # Template job fields (matching Job model structure exactly)
      t.string :title
      t.string :location
      t.string :employment_type
      t.string :experience_level
      t.integer :salary_range_min
      t.integer :salary_range_max
      t.string :currency, default: "USD"
      t.boolean :remote_work_allowed, default: false
      
      # Text fields will use Action Text rich text (like Job model)
      # These will be: template_description, template_requirements, 
      # template_qualifications, template_benefits, template_application_instructions
      
      # Multi-tenant and audit fields
      t.uuid :organization_id, null: false
      t.uuid :department_id, null: true
      t.uuid :created_by_id, null: false
      t.uuid :last_used_by_id, null: true
      
      # Usage tracking and metadata
      t.integer :usage_count, default: 0, null: false
      t.datetime :last_used_at
      t.jsonb :settings, default: {} # Template-specific settings
      t.jsonb :default_job_settings, default: {} # Default settings to apply to jobs
      
      # Versioning support
      t.integer :version, default: 1, null: false
      t.uuid :parent_template_id, null: true # For template versioning/forking

      t.timestamps
    end

    # Add foreign key constraints
    add_foreign_key :job_templates, :organizations
    add_foreign_key :job_templates, :departments
    add_foreign_key :job_templates, :users, column: :created_by_id
    add_foreign_key :job_templates, :users, column: :last_used_by_id
    add_foreign_key :job_templates, :job_templates, column: :parent_template_id

    # Add comprehensive indexes for performance
    add_index :job_templates, [:organization_id, :category]
    add_index :job_templates, [:organization_id, :is_active]
    add_index :job_templates, [:organization_id, :name], unique: true
    add_index :job_templates, [:organization_id, :is_default]
    add_index :job_templates, [:department_id]
    add_index :job_templates, [:created_by_id]
    add_index :job_templates, [:last_used_at]
    add_index :job_templates, [:usage_count]
    add_index :job_templates, [:category, :is_active]
    add_index :job_templates, [:parent_template_id]
    add_index :job_templates, :settings, using: :gin
    add_index :job_templates, :default_job_settings, using: :gin

    # Add database constraints for data integrity
    add_check_constraint :job_templates, "name != ''", name: "job_templates_name_not_empty"
    add_check_constraint :job_templates, "category != ''", name: "job_templates_category_not_empty"
    add_check_constraint :job_templates, "usage_count >= 0", name: "job_templates_usage_count_positive"
    add_check_constraint :job_templates, "version >= 1", name: "job_templates_version_positive"
    add_check_constraint :job_templates, "salary_range_min >= 0", name: "job_templates_salary_range_min_positive"
    add_check_constraint :job_templates, "salary_range_max >= salary_range_min", name: "job_templates_salary_range_max_gte_min"
    add_check_constraint :job_templates, 
                        "employment_type IN ('full_time', 'part_time', 'contract', 'temporary', 'internship')", 
                        name: "job_templates_employment_type_valid"
    add_check_constraint :job_templates, 
                        "experience_level IN ('entry', 'junior', 'mid', 'senior', 'lead', 'executive')", 
                        name: "job_templates_experience_level_valid"
    add_check_constraint :job_templates,
                        "category IN ('engineering', 'sales', 'marketing', 'design', 'hr', 'finance', 'operations', 'customer_success', 'product', 'legal', 'executive', 'other')",
                        name: "job_templates_category_valid"

    # Ensure only one default template per category per organization
    add_index :job_templates, [:organization_id, :category], 
              unique: true, 
              where: "is_default = true",
              name: "index_job_templates_unique_default_per_category"
  end
end
