class AddJobTemplateToJobs < ActiveRecord::Migration[8.0]
  def change
    add_column :jobs, :job_template_id, :uuid, null: true
    add_foreign_key :jobs, :job_templates, column: :job_template_id
    add_index :jobs, :job_template_id
  end
end
