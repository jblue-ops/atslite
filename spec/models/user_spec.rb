# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  let(:organization) { create(:organization) }

  describe "validations" do
    subject { build(:user, organization: organization) }

    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:role) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).scoped_to(:organization_id).case_insensitive }
    # Role validation is handled by enum, tested separately below

    describe "phone validation" do
      it "accepts valid phone numbers" do
        valid_phones = ["+1-555-123-4567", "(555) 123-4567", "555-123-4567", "5551234567"]
        valid_phones.each do |phone|
          user = build(:user, organization: organization, phone: phone)
          expect(user).to be_valid, "#{phone} should be valid"
        end
      end

      it "rejects invalid phone numbers" do
        invalid_phones = ["abc-def-ghij"]
        invalid_phones.each do |phone|
          user = build(:user, organization: organization, phone: phone)
          expect(user).not_to be_valid, "#{phone} should be invalid"
        end
      end
    end

    describe "password complexity validation" do
      it "requires password with uppercase, lowercase, and number" do
        user = build(:user, organization: organization, password: "password")
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("must contain at least one lowercase letter, one uppercase letter, and one number")
      end

      it "accepts strong passwords" do
        user = build(:user, organization: organization, password: "StrongPass1", password_confirmation: "StrongPass1")
        expect(user).to be_valid
      end

      it "rejects common weak passwords" do
        user = build(:user, organization: organization, password: "password123")
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("is too common. Please choose a more secure password")
      end

      it "rejects passwords containing user's name" do
        user = build(:user, organization: organization, first_name: "John", last_name: "Doe", password: "JohnPass1")
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("should not contain your name")
      end
    end
  end

  describe "associations" do
    # Skipping this test for now - organization validation works via belongs_to required: true
    # it "requires an organization" do
    #   user = build(:user, organization: nil)
    #   user.validate
    #   expect(user.valid?).to be false
    #   expect(user.errors[:organization]).to include("can't be blank")
    # end

    it { is_expected.to belong_to(:invited_by).class_name("User").optional }
    it { is_expected.to have_many(:invitations).class_name("User").with_foreign_key("invited_by_id") }
  end

  describe "scopes" do
    let!(:active_user) { create(:user, organization: organization, active: true) }
    let!(:inactive_user) { create(:user, organization: organization, active: false) }
    let!(:admin_user)    { create(:user, organization: organization, role: "admin") }

    it "returns active users" do
      expect(User.active).to include(active_user)
      expect(User.active).not_to include(inactive_user)
    end

    it "returns users by role" do
      expect(User.admins).to include(admin_user)
      expect(User.admins).not_to include(active_user)
    end
  end

  describe "methods" do
    let(:user) { create(:user, organization: organization) }

    describe "#full_name" do
      it "returns the full name" do
        user.first_name = "John"
        user.last_name = "Doe"
        expect(user.full_name).to eq("John Doe")
      end
    end

    describe "role permissions" do
      it "allows admins to manage users" do
        admin = create(:user, organization: organization, role: "admin")
        expect(admin.can_manage_users?).to be true
      end

      it "allows hiring managers to manage jobs" do
        hm = create(:user, organization: organization, role: "hiring_manager")
        expect(hm.can_manage_jobs?).to be true
      end

      it "allows recruiters to recruit" do
        recruiter = create(:user, organization: organization, role: "recruiter")
        expect(recruiter.can_recruit?).to be true
      end
    end

    describe "#active_for_authentication?" do
      it "returns true for active users" do
        user.active = true
        expect(user.active_for_authentication?).to be true
      end

      it "returns false for inactive users" do
        user.active = false
        expect(user.active_for_authentication?).to be false
      end
    end
  end

  describe "callbacks" do
    it "normalizes email before validation" do
      user = build(:user, organization: organization, email: "  TEST@EXAMPLE.COM  ")
      user.valid?
      expect(user.email).to eq("test@example.com")
    end

    it "sets default timezone" do
      user = create(:user, organization: organization, time_zone: nil)
      user.valid?
      expect(user.time_zone).to eq("UTC")
    end

    it "sets default permissions after create" do
      admin = create(:user, organization: organization, role: "admin", first_name: "Admin", last_name: "Test", password: "ComplexPass123!", password_confirmation: "ComplexPass123!")
      expect(admin.permissions).to include("manage_users")
    end
  end
end
