class RemoveNotNullConstraintFromJobTextFields < ActiveRecord::Migration[8.0]
  def change
    # Remove NOT NULL constraints from old text fields that are now handled by Action Text
    change_column_null :jobs, :description, true
    change_column_null :jobs, :requirements, true  
    change_column_null :jobs, :qualifications, true
  end
end
