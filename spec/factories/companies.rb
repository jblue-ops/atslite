# frozen_string_literal: true

FactoryBot.define do
  factory :company do
    name { Faker::Company.name }
    domain { Faker::Internet.domain_name }
    website { "https://#{domain}" }
    description { Faker::Company.catch_phrase }
    industry { Faker::Company.industry }
    size { ["1-10", "11-50", "51-200", "201-500", "501-1000", "1000+"].sample }
    headquarters { "#{Faker::Address.city}, #{Faker::Address.state}" }
    founded_year { rand(1990..2020) }
    active { true }

    # Associations
    after(:create) do |company|
      create(:user, :admin, company: company) unless company.users.admins.exists?
    end

    trait :with_logo do
      after(:build) do |company|
        company.logo.attach(
          io: Rails.root.join("spec", "fixtures", "files", "company_logo.png").open,
          filename: "company_logo.png",
          content_type: "image/png"
        )
      end
    end

    trait :startup do
      size { "1-10" }
      founded_year { rand(2015..2023) }
    end

    trait :enterprise do
      size { "1000+" }
      founded_year { rand(1980..2000) }
    end

    trait :tech_company do
      industry { "Technology" }
    end

    trait :inactive do
      active { false }
      deactivated_at { 1.month.ago }
    end

    trait :with_complete_profile do
      with_logo
      about { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
      benefits { ["Health Insurance", "Remote Work", "401k", "Flexible PTO"] }
      values { %w[Innovation Collaboration Integrity Growth] }
      perks { ["Free lunch", "Gym membership", "Learning budget"] }
    end

    trait :with_multiple_locations do
      after(:create) do |company|
        create_list(:company_location, 3, company: company)
      end
    end

    trait :with_departments do
      after(:create) do |company|
        %w[Engineering Product Marketing Sales HR].each do |dept|
          create(:department, name: dept, company: company)
        end
      end
    end

    # Traits for different subscription levels
    trait :free_plan do
      subscription_plan { "free" }
      job_posting_limit { 3 }
    end

    trait :premium_plan do
      subscription_plan { "premium" }
      job_posting_limit { 25 }
    end

    trait :enterprise_plan do
      subscription_plan { "enterprise" }
      job_posting_limit { nil } # unlimited
    end
  end

  factory :company_location do
    company
    name { "#{Faker::Address.city} Office" }
    address { Faker::Address.full_address }
    city { Faker::Address.city }
    state { Faker::Address.state }
    country { Faker::Address.country }
    is_headquarters { false }

    trait :headquarters do
      is_headquarters { true }
      name { "Headquarters" }
    end
  end

  factory :department do
    organization
    sequence(:name) { |n| "#{%w[Engineering Product Marketing Sales HR Finance].sample} #{n}" }
    description { Faker::Lorem.sentence }
    active { true }

    trait :engineering do
      sequence(:name) { |n| "Engineering #{n}" }
      description { "Responsible for building and maintaining our technology platform" }
    end

    trait :with_parent do
      parent_department { association :department, organization: organization }
    end
  end
end
