# frozen_string_literal: true

FactoryBot.define do
  factory :job do
    organization
    hiring_manager { association :user, :hiring_manager, organization: organization }
    title { Faker::Job.title }
    description { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    requirements { Faker::Lorem.paragraphs(number: 2).join("\n\n") }
    qualifications { Faker::Lorem.paragraph }
    location { "#{Faker::Address.city}, #{Faker::Address.state}" }
    employment_type { %w[full_time part_time contract temporary internship].sample }
    experience_level { %w[entry junior mid senior lead executive].sample }
    salary_range_min { rand(50_000..120_000) }
    salary_range_max { salary_range_min + rand(20_000..80_000) }
    currency { "USD" }
    remote_work_allowed { [true, false].sample }
    status { "draft" }
    department { association :department, organization: organization }
    application_count { 0 }
    view_count { 0 }

    trait :published do
      status { "published" }
      published_at { 1.day.ago }
    end

    trait :closed do
      status { "closed" }
      published_at { 2.days.ago }
    end

    trait :archived do
      status { "archived" }
    end

    trait :remote do
      location { "Remote" }
      remote_work_allowed { true }
    end

    trait :senior_role do
      experience_level { "senior" }
      salary_range_min { 120_000 }
      salary_range_max { 180_000 }
      title { "Senior #{Faker::Job.title}" }
    end

    trait :entry_level do
      experience_level { "entry" }
      salary_range_min { 50_000 }
      salary_range_max { 70_000 }
      title { "Junior #{Faker::Job.title}" }
    end

    trait :contract do
      employment_type { "contract" }
    end

    trait :with_expiration do
      expires_at { 30.days.from_now }
    end

    trait :expired do
      expires_at { 1.day.ago }
      status { "published" }
      published_at { 31.days.ago }
    end

    trait :high_salary do
      salary_range_min { 150_000 }
      salary_range_max { 220_000 }
    end

    trait :no_salary do
      salary_range_min { nil }
      salary_range_max { nil }
    end

    # Industry-specific job templates
    trait :software_engineer do
      title { "Software Engineer" }
      department { "Engineering" }
      experience_level { "mid" }
      requirements do
        "• 3+ years of experience with Ruby on Rails\n" \
          "• Strong understanding of web technologies\n" \
          "• Experience with SQL databases\n" \
          "• Knowledge of version control (Git)"
      end
    end

    trait :product_manager do
      title { "Product Manager" }
      department { "Product" }
      experience_level { "senior" }
      requirements do
        "• 5+ years of product management experience\n" \
          "• Strong analytical and communication skills\n" \
          "• Experience with agile methodologies\n" \
          "• Technical background preferred"
      end
    end

    trait :sales_rep do
      title { "Sales Representative" }
      department { "Sales" }
      experience_level { "mid" }
      employment_type { "full_time" }
    end
  end
end
