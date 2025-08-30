# frozen_string_literal: true

module FullNameable
  extend ActiveSupport::Concern

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def short_name
    "#{first_name} #{last_name[0]}."
  end

  def display_name
    full_name.presence || email
  end

  def initials
    "#{first_name[0]}#{last_name[0]}".upcase if first_name.present? && last_name.present?
  end

  def last_name_first
    "#{last_name}, #{first_name}"
  end
end
