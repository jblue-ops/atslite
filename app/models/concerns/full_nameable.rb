# frozen_string_literal: true

# Concern for models that have first_name and last_name attributes
# Provides methods for full name handling and display
module FullNameable
  extend ActiveSupport::Concern

  # Instance methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def full_name_reversed
    "#{last_name}, #{first_name}".strip
  end

  def initials
    "#{first_name&.first}#{last_name&.first}".upcase
  end

  def display_name
    full_name.presence || email&.split('@')&.first || 'Unknown User'
  end

  def first_name_initial
    "#{first_name&.first}. #{last_name}".strip
  end

  def last_name_initial
    "#{first_name} #{last_name&.first}.".strip
  end

  # Class methods
  class_methods do
    def search_by_name(query)
      return none if query.blank?

      sanitized_query = "%#{query.strip.downcase}%"
      
      where(
        'LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(CONCAT(first_name, \' \', last_name)) LIKE ?',
        sanitized_query, sanitized_query, sanitized_query
      )
    end

    def order_by_name(direction = :asc)
      order(last_name: direction, first_name: direction)
    end

    def order_by_first_name(direction = :asc)
      order(first_name: direction, last_name: direction)
    end
  end

  private

  def normalize_names
    self.first_name = first_name&.strip&.titleize if first_name.present?
    self.last_name = last_name&.strip&.titleize if last_name.present?
  end
end