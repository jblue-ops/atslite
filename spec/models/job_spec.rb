# frozen_string_literal: true

require "rails_helper"

RSpec.describe Job, type: :model do
  let(:organization)   { create(:organization)                                      }
  let(:hiring_manager) { create(:user, :hiring_manager, organization: organization) }

  describe "associations" do
    it { is_expected.to belong_to(:organization) }
    it { is_expected.to belong_to(:hiring_manager).class_name("User") }
    it { is_expected.to belong_to(:department).optional }
    # Future associations - will be tested in later phases
    # it { should have_many(:applications).dependent(:destroy) }
    # it { should have_many(:candidates).through(:applications) }
    # it { should have_many(:interviews).through(:applications) }
  end

  describe "validations" do
    subject { build(:job, organization: organization, hiring_manager: hiring_manager) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_length_of(:title).is_at_least(3).is_at_most(200) }
    it { is_expected.to validate_length_of(:description).is_at_least(10) }

    it { is_expected.to validate_inclusion_of(:employment_type).in_array(%w[full_time part_time contract temporary internship]) }
    it { is_expected.to validate_inclusion_of(:experience_level).in_array(%w[entry junior mid senior lead executive]).allow_blank }

    it { is_expected.to validate_numericality_of(:salary_range_min).is_greater_than_or_equal_to(0).allow_blank }
    it { is_expected.to validate_numericality_of(:salary_range_max).is_greater_than_or_equal_to(0).allow_blank }
    it { is_expected.to validate_numericality_of(:application_count).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:view_count).is_greater_than_or_equal_to(0) }

    describe "currency validation" do
      it "validates currency format" do
        job = build(:job, currency: "USD", organization: organization, hiring_manager: hiring_manager)
        expect(job).to be_valid

        job.currency = "invalid"
        expect(job).not_to be_valid
        expect(job.errors[:currency]).to include("must be a valid 3-letter currency code")
      end
    end

    describe "salary range consistency" do
      it "validates that max salary is greater than or equal to min salary" do
        job = build(:job,
                    salary_range_min: 100_000,
                    salary_range_max: 80_000,
                    organization: organization,
                    hiring_manager: hiring_manager)
        expect(job).not_to be_valid
        expect(job.errors[:salary_range_max]).to include("must be greater than or equal to minimum salary")
      end

      it "allows equal min and max salaries" do
        job = build(:job,
                    salary_range_min: 100_000,
                    salary_range_max: 100_000,
                    organization: organization,
                    hiring_manager: hiring_manager)
        expect(job).to be_valid
      end
    end

    describe "hiring manager validation" do
      it "validates that hiring manager belongs to same organization" do
        other_org = create(:organization)
        other_manager = create(:user, :hiring_manager, organization: other_org)

        job = build(:job, organization: organization, hiring_manager: other_manager)
        expect(job).not_to be_valid
        expect(job.errors[:hiring_manager]).to include("must belong to the same organization")
      end
    end
  end

  describe "scopes" do
    let!(:draft_job) { create(:job, status: "draft", organization: organization, hiring_manager: hiring_manager) }
    let!(:published_job) { create(:job, :published, organization: organization, hiring_manager: hiring_manager) }
    let!(:closed_job)    { create(:job, :closed, organization: organization, hiring_manager: hiring_manager)    }
    let!(:archived_job)  { create(:job, :archived, organization: organization, hiring_manager: hiring_manager)  }
    let!(:remote_job)    { create(:job, :remote, organization: organization, hiring_manager: hiring_manager)    }

    it "filters by status correctly" do
      expect(described_class.draft).to contain_exactly(draft_job)
      expect(described_class.published).to contain_exactly(published_job)
      expect(described_class.closed).to contain_exactly(closed_job)
      expect(described_class.archived).to contain_exactly(archived_job)
      expect(described_class.active).to contain_exactly(published_job)
    end

    it "filters remote-friendly jobs" do
      expect(described_class.remote_friendly).to contain_exactly(remote_job)
    end

    it "filters by experience level" do
      senior_job = create(:job, :senior_role, organization: organization, hiring_manager: hiring_manager)
      expect(described_class.by_experience_level("senior")).to contain_exactly(senior_job)
    end
  end

  describe "state machine" do
    let(:job) { create(:job, organization: organization, hiring_manager: hiring_manager) }

    it "starts in draft state" do
      expect(job.status).to eq("draft")
    end

    describe "publish event" do
      it "transitions from draft to published" do
        expect(job.publish).to be true
        expect(job.status).to eq("published")
        expect(job.published_at).to be_present
      end
    end

    describe "close event" do
      let(:published_job) { create(:job, :published, organization: organization, hiring_manager: hiring_manager) }

      it "transitions from published to closed" do
        expect(published_job.close).to be true
        expect(published_job.status).to eq("closed")
      end
    end
  end

  describe "class methods" do
    describe ".search" do
      let!(:job1) { create(:job, title: "Ruby Developer", organization: organization, hiring_manager: hiring_manager) }
      let!(:job2) { create(:job, description: "Looking for Python skills", organization: organization, hiring_manager: hiring_manager) }

      it "searches by title" do
        expect(described_class.search("Ruby")).to contain_exactly(job1)
      end

      it "searches by description" do
        expect(described_class.search("Python")).to contain_exactly(job2)
      end
    end
  end

  describe "instance methods" do
    let(:job) { create(:job, organization: organization, hiring_manager: hiring_manager) }

    describe "#display_title" do
      it "returns title when present" do
        job.title = "Software Engineer"
        expect(job.display_title).to eq("Software Engineer")
      end
    end

    describe "#salary_range_display" do
      it "shows full range when both set" do
        job.salary_range_min = 80_000
        job.salary_range_max = 120_000
        expect(job.salary_range_display).to eq("USD 80K - 120K")
      end
    end

    describe "#can_be_published?" do
      it "returns true when all required fields present" do
        job.title = "Developer"
        job.description = "Great opportunity"
        expect(job.can_be_published?).to be true
      end
    end
  end

  describe "callbacks" do
    describe "after_create" do
      it "sets default settings" do
        job = create(:job, organization: organization, hiring_manager: hiring_manager)
        expect(job.setting("auto_reject_after_days")).to eq(30)
      end
    end
  end

  describe "multi-tenant support" do
    it "scopes jobs to organization" do
      org1 = create(:organization)
      org2 = create(:organization)
      manager1 = create(:user, :hiring_manager, organization: org1)
      manager2 = create(:user, :hiring_manager, organization: org2)

      job1 = create(:job, organization: org1, hiring_manager: manager1)
      create(:job, organization: org2, hiring_manager: manager2)

      ActsAsTenant.with_tenant(org1) do
        expect(described_class.all).to contain_exactly(job1)
      end
    end
  end
end
