class FixActionTextRecordIdForUuids < ActiveRecord::Migration[8.0]
  def change
    # Change record_id column from bigint to string to support UUID primary keys
    change_column :action_text_rich_texts, :record_id, :string, null: false
  end
end
