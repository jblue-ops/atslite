# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserPolicy, type: :policy do
  let(:organization)       { create(:organization) }
  let(:other_organization) { create(:organization) }

  let(:admin_user) { create(:user, :admin, organization: organization) }
  let(:hiring_manager_user) { create(:user, :hiring_manager, organization: organization)    }
  let(:recruiter_user)      { create(:user, :recruiter, organization: organization)         }
  let(:interviewer_user)    { create(:user, :interviewer, organization: organization)       }
  let(:coordinator_user)    { create(:user, :coordinator, organization: organization)       }

  let(:regular_user) { create(:user, organization: organization) }
  let(:other_org_user) { create(:user, organization: other_organization) }

  describe "#index?" do
    it "grants access to admins only" do
      expect(described_class.new(admin_user, User).index?).to be true
      expect(described_class.new(regular_user, User).index?).to be false
      expect(described_class.new(recruiter_user, User).index?).to be false
    end
  end

  describe "#show?" do
    it "allows users to view their own profile" do
      expect(described_class.new(regular_user, regular_user).show?).to be true
      expect(described_class.new(admin_user, admin_user).show?).to be true
    end

    it "allows admins to view any user in their organization" do
      expect(described_class.new(admin_user, regular_user).show?).to be true
      expect(described_class.new(admin_user, recruiter_user).show?).to be true
    end

    it "denies non-admins from viewing other users" do
      expect(described_class.new(regular_user, recruiter_user).show?).to be false
      expect(described_class.new(recruiter_user, regular_user).show?).to be false
    end

    it "denies viewing users from other organizations" do
      expect(described_class.new(admin_user, other_org_user).show?).to be false
    end
  end

  describe "#create?" do
    it "grants access to admins only" do
      expect(described_class.new(admin_user, User).create?).to be true
      expect(described_class.new(regular_user, User).create?).to be false
      expect(described_class.new(recruiter_user, User).create?).to be false
    end
  end

  describe "#update?" do
    it "allows users to update their own profile" do
      expect(described_class.new(regular_user, regular_user).update?).to be true
      expect(described_class.new(admin_user, admin_user).update?).to be true
    end

    it "allows admins to update any user in their organization" do
      expect(described_class.new(admin_user, regular_user).update?).to be true
      expect(described_class.new(admin_user, recruiter_user).update?).to be true
    end

    it "denies non-admins from updating other users" do
      expect(described_class.new(regular_user, recruiter_user).update?).to be false
      expect(described_class.new(recruiter_user, regular_user).update?).to be false
    end
  end

  describe "#destroy?" do
    it "denies users from deleting themselves" do
      expect(described_class.new(admin_user, admin_user).destroy?).to be false
      expect(described_class.new(regular_user, regular_user).destroy?).to be false
    end

    it "allows admins to delete other users" do
      expect(described_class.new(admin_user, regular_user).destroy?).to be true
      expect(described_class.new(admin_user, recruiter_user).destroy?).to be true
    end

    it "denies non-admins from deleting users" do
      expect(described_class.new(regular_user, recruiter_user).destroy?).to be false
      expect(described_class.new(recruiter_user, regular_user).destroy?).to be false
    end
  end

  describe "#activate? and #deactivate?" do
    it "allows admins to activate/deactivate other users" do
      expect(described_class.new(admin_user, regular_user).activate?).to be true
      expect(described_class.new(admin_user, regular_user).deactivate?).to be true
      expect(described_class.new(admin_user, admin_user).activate?).to be false # cannot activate/deactivate self
      expect(described_class.new(admin_user, admin_user).deactivate?).to be false
    end

    it "denies non-admins from activating/deactivating users" do
      expect(described_class.new(regular_user, recruiter_user).activate?).to be false
      expect(described_class.new(recruiter_user, regular_user).deactivate?).to be false
    end
  end

  describe "#change_role?" do
    it "allows admins to change other users' roles" do
      expect(described_class.new(admin_user, regular_user).change_role?).to be true
      expect(described_class.new(admin_user, admin_user).change_role?).to be false # cannot change own role
    end

    it "denies non-admins from changing roles" do
      expect(described_class.new(regular_user, recruiter_user).change_role?).to be false
      expect(described_class.new(hiring_manager_user, recruiter_user).change_role?).to be false
    end
  end

  describe "#invite?" do
    it "allows admins and hiring managers to invite users" do
      expect(described_class.new(admin_user, User).invite?).to be true
      expect(described_class.new(hiring_manager_user, User).invite?).to be true
    end

    it "denies other roles from inviting users" do
      expect(described_class.new(recruiter_user, User).invite?).to be false
      expect(described_class.new(interviewer_user, User).invite?).to be false
      expect(described_class.new(coordinator_user, User).invite?).to be false
    end
  end

  describe "#manage_permissions?" do
    it "grants access to admins only" do
      expect(described_class.new(admin_user, regular_user).manage_permissions?).to be true
      expect(described_class.new(hiring_manager_user, regular_user).manage_permissions?).to be false
      expect(described_class.new(recruiter_user, regular_user).manage_permissions?).to be false
    end
  end

  describe "Scope" do
    it "returns all users in organization for admins" do
      # Ensure all users are created
      users_in_org = [admin_user, hiring_manager_user, recruiter_user, regular_user]
      other_org_user # Create the other org user too

      scope = Pundit.policy_scope(admin_user, User.all)
      expect(scope).to match_array(users_in_org)
    end

    it "returns only self for non-admin users" do
      # Create the users first
      admin_user
      regular_user

      scope = Pundit.policy_scope(regular_user, User.all)
      expect(scope).to contain_exactly(regular_user)
    end

    it "excludes users from other organizations" do
      # Ensure all users are created
      admin_user
      other_org_user

      scope = Pundit.policy_scope(admin_user, User.all)
      expect(scope).not_to include(other_org_user)
    end
  end
end
