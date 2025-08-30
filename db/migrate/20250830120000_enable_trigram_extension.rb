# frozen_string_literal: true

class EnableTrigramExtension < ActiveRecord::Migration[7.2]
  def change
    # Enable pg_trgm extension for trigram-based text search indexes
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
  end
end