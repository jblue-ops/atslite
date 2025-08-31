# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobTemplate, type: :model do
  let(:organization) { create(:organization)                           }
  let(:user)         { create(:user, organization: organization)       }
  let(:department)   { create(:department, organization: organization) }

  describe "associations" do
    it { is_expected.to belong_to(:organization) }
    it { is_expected.to belong_to(:department).optional }
    it { is_expected.to belong_to(:created_by).class_name("User") }
    it { is_expected.to belong_to(:last_used_by).class_name("User").optional }
    it { is_expected.to belong_to(:parent_template).class_name("JobTemplate").optional }
    it { is_expected.to have_many(:child_templates).class_name("JobTemplate").with_foreign_key(:parent_template_id) }
    it { is_expected.to have_many(:jobs) }
    it { is_expected.to have_rich_text(:template_description) }
    it { is_expected.to have_rich_text(:template_requirements) }
    it { is_expected.to have_rich_text(:template_qualifications) }
    it { is_expected.to have_rich_text(:template_benefits) }
    it { is_expected.to have_rich_text(:template_application_instructions) }
  end

  describe "validations" do
    subject { build(:job_template, organization: organization, created_by: user) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_least(3).is_at_most(200) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:organization_id) }
    it { is_expected.to validate_inclusion_of(:category).in_array(%w[engineering sales marketing design hr finance operations customer_success product legal executive other]) }
    it { is_expected.to validate_inclusion_of(:employment_type).in_array(%w[full_time part_time contract temporary internship]).allow_blank }
    it { is_expected.to validate_inclusion_of(:experience_level).in_array(%w[entry junior mid senior lead executive]).allow_blank }
    it { is_expected.to validate_numericality_of(:usage_count).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:version).is_greater_than_or_equal_to(1) }
    it { is_expected.to validate_numericality_of(:salary_range_min).is_greater_than_or_equal_to(0).allow_blank }
    it { is_expected.to validate_numericality_of(:salary_range_max).is_greater_than_or_equal_to(0).allow_blank }

    describe "salary range consistency" do
      it "validates that max salary is greater than or equal to min salary" do
        template = build(:job_template, salary_range_min: 100_000, salary_range_max: 80_000)
        expect(template).not_to be_valid
        expect(template.errors[:salary_range_max]).to include("must be greater than or equal to minimum salary")
      end

      it "allows equal min and max salaries" do
        template = build(:job_template, salary_range_min: 100_000, salary_range_max: 100_000)
        expect(template).to be_valid
      end
    end

    describe "organizational constraints" do
      let(:other_organization) { create(:organization) }
      let(:other_user) { create(:user, organization: other_organization) }

      it "validates created_by belongs to same organization" do
        template = build(:job_template, organization: organization, created_by: other_user)
        expect(template).not_to be_valid
        expect(template.errors[:created_by]).to include("must belong to the same organization")
      end

      it "validates last_used_by belongs to same organization" do
        template = build(:job_template, organization: organization, created_by: user, last_used_by: other_user)
        expect(template).not_to be_valid
        expect(template.errors[:last_used_by]).to include("must belong to the same organization")
      end

      it "validates parent_template belongs to same organization" do
        parent_template = create(:job_template, organization: other_organization, created_by: other_user)
        template = build(:job_template, organization: organization, created_by: user, parent_template: parent_template)
        expect(template).not_to be_valid
        expect(template.errors[:parent_template]).to include("must belong to the same organization")
      end
    end

    describe "default template constraints" do
      it "allows only one default template per category per organization" do
        create(:job_template, organization: organization, created_by: user, category: "engineering", is_default: true)

        duplicate_default = build(:job_template, organization: organization, created_by: user, category: "engineering", is_default: true)
        expect(duplicate_default).not_to be_valid
        expect(duplicate_default.errors[:is_default]).to include("can only have one default template per category")
      end

      it "allows default templates in different categories" do
        create(:job_template, organization: organization, created_by: user, category: "engineering", is_default: true)

        other_category_default = build(:job_template, organization: organization, created_by: user, category: "sales", is_default: true)
        expect(other_category_default).to be_valid
      end
    end
  end

  describe "scopes" do
    let!(:active_template) { create(:job_template, organization: organization, created_by: user, is_active: true) }
    let!(:inactive_template)    { create(:job_template, organization: organization, created_by: user, is_active: false)        }
    let!(:default_template)     { create(:job_template, organization: organization, created_by: user, is_default: true)        }
    let!(:engineering_template) { create(:job_template, organization: organization, created_by: user, category: "engineering") }

    it "filters by active status" do
      expect(described_class.active).to include(active_template)
      expect(described_class.active).not_to include(inactive_template)
    end

    it "filters by inactive status" do
      expect(described_class.inactive).to include(inactive_template)
      expect(described_class.inactive).not_to include(active_template)
    end

    it "filters default templates" do
      expect(described_class.default_templates).to include(default_template)
      expect(described_class.default_templates).not_to include(active_template)
    end

    it "filters by category" do
      expect(described_class.by_category("engineering")).to include(engineering_template)
    end

    it "filters by organization" do
      other_org = create(:organization)
      other_user = create(:user, organization: other_org)
      other_template = create(:job_template, organization: other_org, created_by: other_user)

      expect(described_class.by_organization(organization)).to include(active_template)
      expect(described_class.by_organization(organization)).not_to include(other_template)
    end
  end

  describe "validations" do
    describe "category validation" do
      it "allows valid categories" do
        valid_categories = %w[engineering sales marketing design hr finance operations customer_success product legal executive other]
        valid_categories.each do |category|
          template = build(:job_template, category: category)
          expect(template).to be_valid
        end
      end

      it "rejects invalid categories" do
        template = build(:job_template, category: "invalid_category")
        expect(template).not_to be_valid
        expect(template.errors[:category]).to include("must be a valid category")
      end
    end

    describe "employment_type validation" do
      it "allows valid employment types" do
        valid_types = %w[full_time part_time contract temporary internship]
        valid_types.each do |type|
          template = build(:job_template, employment_type: type)
          expect(template).to be_valid
        end
      end

      it "allows blank employment type" do
        template = build(:job_template, employment_type: nil)
        expect(template).to be_valid
      end
    end

    describe "experience_level validation" do
      it "allows valid experience levels" do
        valid_levels = %w[entry junior mid senior lead executive]
        valid_levels.each do |level|
          template = build(:job_template, experience_level: level)
          expect(template).to be_valid
        end
      end

      it "allows blank experience level" do
        template = build(:job_template, experience_level: nil)
        expect(template).to be_valid
      end
    end
  end

  describe "instance methods" do
    let(:template) { create(:job_template, organization: organization, created_by: user, name: "Software Engineer Template") }

    describe "#display_name" do
      it "returns the name when present" do
        expect(template.display_name).to eq("Software Engineer Template")
      end

      it "returns 'Untitled Template' when name is blank" do
        template.name = ""
        expect(template.display_name).to eq("Untitled Template")
      end
    end

    describe "#category_display" do
      it "returns humanized category" do
        template.category = "customer_success"
        expect(template.category_display).to eq("Customer Success")
      end
    end

    describe "tag management" do
      it "manages tags as an array" do
        template.tags = "ruby, rails, postgresql"
        expect(template.tags_array).to eq(%w[ruby rails postgresql])
      end

      it "adds tags" do
        template.add_tag("javascript")
        expect(template.tags_array).to include("javascript")
      end

      it "removes tags" do
        template.tags = "ruby, rails"
        template.remove_tag("ruby")
        expect(template.tags_array).not_to include("ruby")
      end

      it "checks if has tag" do
        template.tags = "ruby, rails"
        expect(template).to have_tag("ruby")
        expect(template).not_to have_tag("python")
      end
    end

    describe "usage tracking" do
      it "increments usage count" do
        expect { template.increment_usage! }.to change(template, :usage_count).by(1)
      end

      it "marks as used by user" do
        template.mark_used_by!(user)
        expect(template.reload.last_used_by).to eq(user)
        expect(template.last_used_at).to be_present
      end
    end

    describe "template management" do
      it "deactivates template" do
        template.deactivate!
        expect(template.reload).not_to be_is_active
      end

      it "activates template" do
        template.update!(is_active: false)
        template.activate!
        expect(template.reload).to be_is_active
      end

      it "makes template default" do
        template.make_default!
        expect(template.reload).to be_is_default
      end

      it "removes default status from other templates when making one default" do
        existing_default = create(:job_template,
                                  organization: organization,
                                  created_by: user,
                                  category: template.category,
                                  is_default: true)

        template.make_default!
        expect(existing_default.reload).not_to be_is_default
        expect(template.reload).to be_is_default
      end
    end

    describe "#duplicate!" do
      let!(:original) do
        create(:job_template,
               organization: organization,
               created_by: user,
               name: "Original Template",
               title: "Software Engineer",
               usage_count: 5,
               is_default: true)
      end

      it "creates a copy with proper defaults" do
        copy = original.duplicate!

        expect(copy.name).to eq("Original Template (Copy)")
        expect(copy.title).to eq("Software Engineer")
        expect(copy.usage_count).to eq(0)
        expect(copy.is_default).to be_falsy
        expect(copy.parent_template).to eq(original)
        expect(copy.version).to eq(1)
        expect(copy).to be_persisted
      end

      it "accepts custom name" do
        copy = original.duplicate!(new_name: "Custom Copy Name")
        expect(copy.name).to eq("Custom Copy Name")
      end

      it "accepts different creator" do
        other_user = create(:user, organization: organization)
        copy = original.duplicate!(created_by_user: other_user)
        expect(copy.created_by).to eq(other_user)
      end
    end

    describe "content methods" do
      it "checks if has content" do
        expect(template).not_to have_content

        template.template_description = "Some description"
        expect(template).to have_content
      end

      it "checks if content is complete" do
        expect(template).not_to be_content_complete

        template.title = "Software Engineer"
        template.template_description = "Job description"
        template.employment_type = "full_time"

        expect(template).to be_content_complete
      end
    end

    describe "versioning methods" do
      let(:parent) { create(:job_template, organization: organization, created_by: user)                                      }
      let(:child)  { create(:job_template, organization: organization, created_by: user, parent_template: parent, version: 2) }

      it "identifies root templates" do
        expect(parent).to be_is_root_template
        expect(child).not_to be_is_root_template
      end

      it "builds version chain" do
        chain = child.version_chain
        expect(chain).to eq([parent, child])
      end

      it "finds latest version" do
        latest_child = create(:job_template, organization: organization, created_by: user, parent_template: parent, version: 3)
        expect(parent.latest_version).to eq(latest_child)
      end
    end
  end

  describe "job creation from template" do
    let!(:template) do
      create(:job_template,
             organization: organization,
             created_by: user,
             department: department,
             title: "Senior Software Engineer",
             location: "San Francisco, CA",
             employment_type: "full_time",
             experience_level: "senior",
             salary_range_min: 120_000_00, # $120,000 in cents
             salary_range_max: 160_000_00, # $160,000 in cents
             currency: "USD",
             remote_work_allowed: true)
    end

    let(:hiring_manager) { create(:user, organization: organization, role: "hiring_manager") }

    before do
      template.template_description = "We are looking for a senior software engineer..."
      template.template_requirements = "5+ years of experience..."
      template.template_qualifications = "Bachelor's degree in Computer Science..."
      template.save!
    end

    describe "#apply_to_job!" do
      it "creates a new job with template attributes" do
        job = template.apply_to_job!({ hiring_manager: hiring_manager }, user: user)

        expect(job).to be_a(Job)
        expect(job.title).to eq("Senior Software Engineer")
        expect(job.location).to eq("San Francisco, CA")
        expect(job.employment_type).to eq("full_time")
        expect(job.experience_level).to eq("senior")
        expect(job.salary_range_min).to eq(120_000_00)
        expect(job.salary_range_max).to eq(160_000_00)
        expect(job.organization).to eq(organization)
        expect(job.job_template).to eq(template)
        expect(job.hiring_manager).to eq(hiring_manager)
        expect(job.description.to_s).to include("We are looking for a senior software engineer")
      end

      it "allows overriding template attributes" do
        job = template.apply_to_job!({
                                       title: "Staff Software Engineer",
                                       salary_range_min: 150_000_00,
                                       hiring_manager: hiring_manager
                                     }, user: user)

        expect(job.title).to eq("Staff Software Engineer")
        expect(job.salary_range_min).to eq(150_000_00)
        expect(job.location).to eq("San Francisco, CA") # Preserved from template
      end

      it "marks template as used" do
        expect do
          template.apply_to_job!({ hiring_manager: hiring_manager }, user: user)
        end.to change(template, :usage_count).by(1)

        expect(template.reload.last_used_by).to eq(user)
      end

      it "raises error for user from different organization" do
        other_org = create(:organization)
        other_user = create(:user, organization: other_org)

        expect do
          template.apply_to_job!({}, user: other_user)
        end.to raise_error(ArgumentError, "User must belong to the same organization as the template")
      end
    end

    describe "#create_job_from_template!" do
      it "creates and persists a job from template" do
        job = template.create_job_from_template!({ hiring_manager: hiring_manager }, user: user)

        expect(job).to be_persisted
        expect(job.job_template_id).to eq(template.id)
        expect(job.title).to eq("Senior Software Engineer")
      end

      it "raises error on validation failure" do
        expect do
          template.create_job_from_template!({ title: "" }, user: user) # Invalid job
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "settings management" do
    let(:template) { create(:job_template, organization: organization, created_by: user) }

    it "manages template settings" do
      template.set_setting!("custom_setting", "value")
      expect(template.setting("custom_setting")).to eq("value")

      template.remove_setting!("custom_setting")
      expect(template.setting("custom_setting")).to be_nil
    end

    it "manages default job settings" do
      template.set_default_job_setting!("auto_reject_after_days", 45)
      expect(template.default_job_setting("auto_reject_after_days")).to eq(45)

      template.remove_default_job_setting!("auto_reject_after_days")
      expect(template.default_job_setting("auto_reject_after_days")).to be_nil
    end
  end

  describe "class methods" do
    let!(:template1) { create(:job_template, organization: organization, created_by: user, name: "Ruby Engineer", usage_count: 10) }
    let!(:template2) { create(:job_template, organization: organization, created_by: user, name: "Python Developer", usage_count: 5) }

    describe ".search" do
      it "searches by name" do
        results = described_class.search("Ruby")
        expect(results).to include(template1)
        expect(results).not_to include(template2)
      end

      it "returns none for blank query" do
        expect(described_class.search("")).to eq(described_class.none)
      end
    end

    describe ".popular" do
      it "returns most used templates" do
        popular = described_class.popular(1)
        expect(popular.first).to eq(template1)
      end
    end

    describe ".categories_with_counts" do
      it "returns category counts for organization" do
        create(:job_template, organization: organization, created_by: user, category: "engineering")
        create(:job_template, organization: organization, created_by: user, category: "engineering")
        create(:job_template, organization: organization, created_by: user, category: "sales")

        counts = described_class.categories_with_counts(organization)
        expect(counts["engineering"]).to eq(4) # 2 new + 2 existing
        expect(counts["sales"]).to eq(1)
      end
    end
  end

  describe "multi-tenant isolation" do
    let(:org1) { create(:organization) }
    let(:org2)  { create(:organization)             }
    let(:user1) { create(:user, organization: org1) }
    let(:user2) { create(:user, organization: org2) }

    it "isolates templates by organization" do
      template1 = create(:job_template, organization: org1, created_by: user1)
      template2 = create(:job_template, organization: org2, created_by: user2)

      ActsAsTenant.with_tenant(org1) do
        expect(described_class.all).to include(template1)
        expect(described_class.all).not_to include(template2)
      end

      ActsAsTenant.with_tenant(org2) do
        expect(described_class.all).to include(template2)
        expect(described_class.all).not_to include(template1)
      end
    end
  end

  describe "callbacks and lifecycle" do
    it "sets default settings after creation" do
      template = create(:job_template, organization: organization, created_by: user)

      expect(template.settings["auto_apply_department"]).to be(true)
      expect(template.settings["preserve_rich_text_formatting"]).to be(true)
      expect(template.default_job_settings["auto_reject_after_days"]).to eq(30)
      expect(template.default_job_settings["send_confirmation_email"]).to be(true)
    end

    it "normalizes fields before validation" do
      template = create(:job_template,
                        organization: organization,
                        created_by: user,
                        name: "  Spaced   Name  ",
                        title: "  Spaced   Title  ",
                        currency: "usd")

      expect(template.name).to eq("Spaced Name")
      expect(template.title).to eq("Spaced Title")
      expect(template.currency).to eq("USD")
    end

    it "increments version on content changes" do
      template = create(:job_template, organization: organization, created_by: user, title: "Original Title")
      original_version = template.version

      template.update!(title: "Updated Title")
      expect(template.version).to eq(original_version + 1)
    end

    it "does not increment version on metadata changes" do
      template = create(:job_template, organization: organization, created_by: user)
      original_version = template.version

      template.update!(name: "New Name")
      expect(template.version).to eq(original_version)
    end
  end
end
