class EnablePgSearchExtensions < ActiveRecord::Migration[8.0]
  def change
    # Enable PostgreSQL extensions for advanced search
    enable_extension 'pg_trgm'    # Trigram similarity matching
    enable_extension 'unaccent'   # Remove accents from text for better search
  end
end
