# frozen_string_literal: true

class CreateCompanies < ActiveRecord::Migration[7.2]
  def change
    # Enable UUID extension if not already enabled
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
    
    create_table :companies, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :email_domain
      t.integer :subscription_plan, null: false, default: 0
      t.jsonb :settings, null: false, default: {}

      t.timestamps null: false
    end

    # Add indexes for performance
    add_index :companies, :name
    add_index :companies, :slug, unique: true
    add_index :companies, :email_domain
    add_index :companies, :subscription_plan
    add_index :companies, :settings, using: :gin

    # Add check constraint for subscription_plan enum
    execute <<-SQL
      ALTER TABLE companies
      ADD CONSTRAINT companies_subscription_plan_check
      CHECK (subscription_plan IN (0, 1, 2));
    SQL

    # Add check constraint for slug format (URL-friendly)
    execute <<-SQL
      ALTER TABLE companies
      ADD CONSTRAINT companies_slug_format_check
      CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$');
    SQL

    # Add check constraint for email_domain format
    execute <<-SQL
      ALTER TABLE companies
      ADD CONSTRAINT companies_email_domain_format_check
      CHECK (email_domain IS NULL OR email_domain ~ '^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}$');
    SQL
  end
end