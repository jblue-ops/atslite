class AddBenefitsAndApplicationInstructionsToJobs < ActiveRecord::Migration[8.0]
  def change
    add_column :jobs, :benefits, :text
    add_column :jobs, :application_instructions, :text
  end
end
