# frozen_string_literal: true

FactoryBot.define do
  factory :job_template do
    organization { create(:organization) }
    created_by { create(:user, :hiring_manager, organization: organization) }

    name { "#{Faker::Job.title} Template" }
    description { Faker::Lorem.paragraph }
    category { %w[engineering sales marketing design hr finance operations customer_success product legal executive other].sample }

    # Job template fields
    title { Faker::Job.title }
    employment_type { %w[full_time part_time contract temporary internship].sample }
    experience_level { %w[entry junior mid senior lead executive].sample }
    location { "#{Faker::Address.city}, #{Faker::Address.state_abbr}" }
    currency { "USD" }
    salary_range_min { rand(50_000..80_000) }
    salary_range_max { salary_range_min + rand(10_000..50_000) }
    remote_work_allowed { [true, false].sample }

    # Template metadata
    is_active { true }
    is_default { false }
    usage_count { 0 }
    version { 1 }

    # Settings
    settings { {} }
    default_job_settings { {} }

    # Tags
    tags { [Faker::Company.industry, Faker::Job.field].uniq }

    transient do
      with_content { false }
    end

    after(:build) do |template, evaluator|
      if evaluator.with_content
        template.template_description = Faker::Lorem.paragraphs(number: 3).join("\n\n")
        template.template_requirements = Faker::Lorem.paragraphs(number: 2).join("\n\n")
        template.template_qualifications = Faker::Lorem.paragraphs(number: 2).join("\n\n")
        template.template_benefits = Faker::Lorem.paragraphs(number: 1).join("\n\n")
        template.template_application_instructions = Faker::Lorem.paragraph
      end
    end

    trait :engineering do
      category { "engineering" }
      title { "Software Engineer" }
      employment_type { "full_time" }
      experience_level { "mid" }
    end

    trait :sales do
      category { "sales" }
      title { "Sales Representative" }
      employment_type { "full_time" }
      experience_level { "junior" }
    end

    trait :hr do
      category { "hr" }
      title { "HR Specialist" }
      employment_type { "full_time" }
      experience_level { "mid" }
    end

    trait :inactive do
      is_active { false }
    end

    trait :default do
      is_default { true }
    end

    trait :with_parent do
      association :parent_template, factory: :job_template
      after(:build) do |template|
        template.version = template.parent_template.version + 1 if template.parent_template
      end
    end

    trait :senior_role do
      experience_level { "senior" }
      salary_range_min { 100_000 }
      salary_range_max { 150_000 }
    end
  end
end
