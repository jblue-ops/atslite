# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid, index: true
      t.string :email, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.integer :role, null: false, default: 0
      t.jsonb :settings, null: false, default: {}
      t.datetime :last_login_at

      t.timestamps null: false
    end

    # Add comprehensive indexes for performance
    add_index :users, :email, unique: true
    # company_id index is automatically created by foreign key reference
    add_index :users, :role
    add_index :users, :last_login_at
    add_index :users, [:company_id, :role], name: 'index_users_on_company_and_role'
    add_index :users, [:company_id, :email], unique: true, name: 'index_users_on_company_and_email'
    add_index :users, :settings, using: :gin
    add_index :users, [:first_name, :last_name], name: 'index_users_on_full_name'

    # Add check constraint for role enum
    execute <<-SQL
      ALTER TABLE users
      ADD CONSTRAINT users_role_check
      CHECK (role IN (0, 1, 2, 3));
    SQL

    # Add check constraint for email format
    execute <<-SQL
      ALTER TABLE users
      ADD CONSTRAINT users_email_format_check
      CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    SQL

    # Add check constraint for name format (no empty strings)
    execute <<-SQL
      ALTER TABLE users
      ADD CONSTRAINT users_first_name_not_empty_check
      CHECK (length(trim(first_name)) > 0);
    SQL

    execute <<-SQL
      ALTER TABLE users
      ADD CONSTRAINT users_last_name_not_empty_check
      CHECK (length(trim(last_name)) > 0);
    SQL
  end
end