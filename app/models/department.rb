# frozen_string_literal: true

class Department < ApplicationRecord
  belongs_to :organization
  belongs_to :parent_department, class_name: "Department", optional: true
  has_many :sub_departments, class_name: "Department", foreign_key: "parent_department_id", dependent: :destroy
  has_many :jobs, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: { scope: :organization_id }
  validates :code, uniqueness: { scope: :organization_id }, allow_blank: true

  scope :active, -> { where(active: true) }
  scope :top_level, -> { where(parent_department_id: nil) }

  acts_as_tenant :organization

  def display_name
    name.presence || "Unnamed Department"
  end

  def full_name
    return name if parent_department.blank?

    "#{parent_department.full_name} > #{name}"
  end
end
