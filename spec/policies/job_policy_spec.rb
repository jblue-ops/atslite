# frozen_string_literal: true

RSpec.describe JobPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:other_organization) { create(:organization) }

  # Create users with different roles in the same organization
  let(:admin_user) { create(:user, :admin, organization: organization) }
  let(:hiring_manager) { create(:user, :hiring_manager, organization: organization) }
  let(:recruiter) { create(:user, :recruiter, organization: organization) }
  let(:interviewer) { create(:user, :interviewer, organization: organization) }
  let(:coordinator) { create(:user, :coordinator, organization: organization) }

  # Create users in different organization
  let(:other_admin) { create(:user, :admin, organization: other_organization) }
  let(:other_hiring_manager) { create(:user, :hiring_manager, organization: other_organization) }

  # Create jobs
  let(:job) { create(:job, organization: organization, hiring_manager: hiring_manager) }
  let(:other_job) { create(:job, organization: other_organization, hiring_manager: other_hiring_manager) }
  let(:admin_job) { create(:job, organization: organization, hiring_manager: admin_user) }

  before do
    ActsAsTenant.current_tenant = organization
  end

  describe "Scope" do
    subject { policy_scope }

    def policy_scope
      Pundit.policy_scope(user, Job)
    end

    context "when user is admin" do
      let(:user) { admin_user }

      it "includes all jobs in the organization" do
        expect(policy_scope).to include(job, admin_job)
        expect(policy_scope).not_to include(other_job)
      end
    end

    context "when user is hiring manager" do
      let(:user) { hiring_manager }

      it "includes all jobs in the organization" do
        expect(policy_scope).to include(job, admin_job)
        expect(policy_scope).not_to include(other_job)
      end
    end

    context "when user is recruiter" do
      let(:user) { recruiter }
      let!(:draft_job) { create(:job, organization: organization, status: "draft") }
      let!(:published_job) { create(:job, :published, organization: organization) }
      let!(:closed_job) { create(:job, :closed, organization: organization) }

      it "includes only published and closed jobs" do
        expect(policy_scope).to include(published_job, closed_job)
        expect(policy_scope).not_to include(draft_job, other_job)
      end
    end

    context "when user is interviewer" do
      let(:user) { interviewer }
      let!(:draft_job) { create(:job, organization: organization, status: "draft") }
      let!(:published_job) { create(:job, :published, organization: organization) }

      it "includes only published jobs" do
        expect(policy_scope).to include(published_job)
        expect(policy_scope).not_to include(draft_job, other_job)
      end
    end

    context "when user is coordinator" do
      let(:user) { coordinator }
      let!(:draft_job) { create(:job, organization: organization, status: "draft") }
      let!(:published_job) { create(:job, :published, organization: organization) }

      it "includes only published jobs" do
        expect(policy_scope).to include(published_job)
        expect(policy_scope).not_to include(draft_job, other_job)
      end
    end
  end

  describe "#index?" do
    subject { JobPolicy.new(user, Job).index? }

    context "when user is authenticated" do
      let(:user) { recruiter }

      it { is_expected.to eq(true) }
    end

    context "when user is not authenticated" do
      let(:user) { nil }

      it { is_expected.to eq(false) }
    end
  end

  describe "#show?" do
    subject { JobPolicy.new(user, job).show? }

    context "when user belongs to same organization" do
      let(:user) { recruiter }

      it { is_expected.to eq(true) }
    end

    context "when user belongs to different organization" do
      let(:user) { other_admin }

      it { is_expected.to eq(false) }
    end

    context "when user is not authenticated" do
      let(:user) { nil }

      it { is_expected.to eq(false) }
    end
  end

  describe "#create?" do
    subject { JobPolicy.new(user, job).create? }

    context "when user is admin" do
      let(:user) { admin_user }

      it { is_expected.to eq(true) }
    end

    context "when user is hiring manager" do
      let(:user) { hiring_manager }

      it { is_expected.to eq(true) }
    end

    context "when user is recruiter" do
      let(:user) { recruiter }

      it { is_expected.to eq(false) }
    end

    context "when user is interviewer" do
      let(:user) { interviewer }

      it { is_expected.to eq(false) }
    end

    context "when user is coordinator" do
      let(:user) { coordinator }

      it { is_expected.to eq(false) }
    end

    context "when user is not authenticated" do
      let(:user) { nil }

      it { is_expected.to eq(false) }
    end
  end

  describe "#new?" do
    subject { JobPolicy.new(user, job).new? }

    it "delegates to create?" do
      expect(subject).to eq(JobPolicy.new(user, job).create?)
    end
  end

  describe "#update?" do
    subject { JobPolicy.new(user, job).update? }

    context "when user is admin in same organization" do
      let(:user) { admin_user }

      it { is_expected.to eq(true) }
    end

    context "when user is job owner (hiring manager)" do
      let(:user) { hiring_manager }

      it { is_expected.to eq(true) }
    end

    context "when user is different hiring manager in same org" do
      let(:other_hiring_manager_same_org) { create(:user, :hiring_manager, organization: organization) }
      let(:user) { other_hiring_manager_same_org }

      it { is_expected.to eq(false) }
    end

    context "when user is recruiter in same organization" do
      let(:user) { recruiter }

      it { is_expected.to eq(false) }
    end

    context "when user belongs to different organization" do
      let(:user) { other_admin }

      it { is_expected.to eq(false) }
    end
  end

  describe "#edit?" do
    subject { JobPolicy.new(user, job).edit? }

    it "delegates to update?" do
      expect(subject).to eq(JobPolicy.new(user, job).update?)
    end
  end

  describe "#destroy?" do
    subject { JobPolicy.new(user, job).destroy? }

    context "when user is admin in same organization" do
      let(:user) { admin_user }

      it { is_expected.to eq(true) }
    end

    context "when user is job owner (hiring manager)" do
      let(:user) { hiring_manager }

      it { is_expected.to eq(true) }
    end

    context "when user is recruiter in same organization" do
      let(:user) { recruiter }

      it { is_expected.to eq(false) }
    end

    context "when user belongs to different organization" do
      let(:user) { other_admin }

      it { is_expected.to eq(false) }
    end
  end

  describe "#publish?" do
    subject { JobPolicy.new(user, draft_job).publish? }

    let(:draft_job) { create(:job, organization: organization, hiring_manager: hiring_manager, status: "draft") }

    before do
      # Ensure job can be published by meeting basic requirements
      draft_job.update!(title: "Valid Title", description: "Valid Description")
    end

    context "when user is admin" do
      let(:user) { admin_user }

      it { is_expected.to eq(true) }
    end

    context "when user is job owner" do
      let(:user) { hiring_manager }

      it { is_expected.to eq(true) }
    end

    context "when user is recruiter" do
      let(:user) { recruiter }

      it { is_expected.to eq(false) }
    end

    context "when job cannot be published" do
      let(:user) { hiring_manager }
      let(:invalid_job) { create(:job, organization: organization, hiring_manager: hiring_manager, title: "", description: "") }

      subject { JobPolicy.new(user, invalid_job).publish? }

      it { is_expected.to eq(false) }
    end
  end

  describe "#close?" do
    subject { JobPolicy.new(user, published_job).close? }

    let(:published_job) { create(:job, :published, organization: organization, hiring_manager: hiring_manager) }

    context "when user is admin" do
      let(:user) { admin_user }

      it { is_expected.to eq(true) }
    end

    context "when user is job owner" do
      let(:user) { hiring_manager }

      it { is_expected.to eq(true) }
    end

    context "when user is recruiter" do
      let(:user) { recruiter }

      it { is_expected.to eq(false) }
    end

    context "when job is not published" do
      let(:user) { hiring_manager }
      let(:draft_job) { create(:job, organization: organization, hiring_manager: hiring_manager, status: "draft") }

      subject { JobPolicy.new(user, draft_job).close? }

      it { is_expected.to eq(false) }
    end
  end

  describe "#reopen?" do
    subject { JobPolicy.new(user, closed_job).reopen? }

    let(:closed_job) { create(:job, :closed, organization: organization, hiring_manager: hiring_manager) }

    context "when user is admin" do
      let(:user) { admin_user }

      it { is_expected.to eq(true) }
    end

    context "when user is job owner" do
      let(:user) { hiring_manager }

      it { is_expected.to eq(true) }
    end

    context "when job is not closed" do
      let(:user) { hiring_manager }
      let(:draft_job) { create(:job, organization: organization, hiring_manager: hiring_manager, status: "draft") }

      subject { JobPolicy.new(user, draft_job).reopen? }

      it { is_expected.to eq(false) }
    end
  end

  describe "#archive?" do
    subject { JobPolicy.new(user, job).archive? }

    context "when user is admin" do
      let(:user) { admin_user }

      it { is_expected.to eq(true) }
    end

    context "when user is job owner" do
      let(:user) { hiring_manager }

      it { is_expected.to eq(true) }
    end

    context "when user is recruiter" do
      let(:user) { recruiter }

      it { is_expected.to eq(false) }
    end
  end

  describe "#unarchive?" do
    subject { JobPolicy.new(user, archived_job).unarchive? }

    let(:archived_job) { create(:job, :archived, organization: organization, hiring_manager: hiring_manager) }

    context "when user is admin" do
      let(:user) { admin_user }

      it { is_expected.to eq(true) }
    end

    context "when user is job owner" do
      let(:user) { hiring_manager }

      it { is_expected.to eq(true) }
    end

    context "when job is not archived" do
      let(:user) { hiring_manager }

      subject { JobPolicy.new(user, job).unarchive? }

      it { is_expected.to eq(false) }
    end
  end

  describe "#view_analytics?" do
    subject { JobPolicy.new(user, job).view_analytics? }

    context "when user is admin" do
      let(:user) { admin_user }

      it { is_expected.to eq(true) }
    end

    context "when user is hiring manager" do
      let(:user) { hiring_manager }

      it { is_expected.to eq(true) }
    end

    context "when user is recruiter" do
      let(:user) { recruiter }

      it { is_expected.to eq(true) }
    end

    context "when user is interviewer" do
      let(:user) { interviewer }

      it { is_expected.to eq(false) }
    end

    context "when user is coordinator" do
      let(:user) { coordinator }

      it { is_expected.to eq(false) }
    end
  end

  describe "#view_applications?" do
    subject { JobPolicy.new(user, job).view_applications? }

    context "when user is admin" do
      let(:user) { admin_user }

      it { is_expected.to eq(true) }
    end

    context "when user is hiring manager" do
      let(:user) { hiring_manager }

      it { is_expected.to eq(true) }
    end

    context "when user is recruiter" do
      let(:user) { recruiter }

      it { is_expected.to eq(true) }
    end

    context "when user is interviewer" do
      let(:user) { interviewer }

      it { is_expected.to eq(false) }
    end
  end

  describe "#manage_applications?" do
    subject { JobPolicy.new(user, job).manage_applications? }

    context "when user is admin" do
      let(:user) { admin_user }

      it { is_expected.to eq(true) }
    end

    context "when user is job owner" do
      let(:user) { hiring_manager }

      it { is_expected.to eq(true) }
    end

    context "when user is recruiter" do
      let(:user) { recruiter }

      it { is_expected.to eq(true) }
    end

    context "when user is interviewer" do
      let(:user) { interviewer }

      it { is_expected.to eq(false) }
    end

    context "when user is coordinator" do
      let(:user) { coordinator }

      it { is_expected.to eq(false) }
    end
  end
end