# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    name { Faker::Company.name }
    website_url { Faker::Internet.url }
    industry { %w[technology healthcare finance education retail manufacturing].sample }
    description { Faker::Company.catch_phrase }
    size_category { %w[startup small medium large enterprise].sample }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :technology do
      industry { "technology" }
      name { "#{Faker::Hacker.adjective.capitalize} #{%w[Tech Solutions Systems Labs].sample}" }
    end

    trait :healthcare do
      industry { "healthcare" }
      name { "#{Faker::Name.last_name} #{%w[Medical Health Clinic Hospital].sample}" }
    end

    trait :startup do
      size_category { "startup" }
      settings do
        {
          "subscription_tier" => "starter",
          "trial_ends_at" => 30.days.from_now.iso8601,
          "email_notifications" => true,
          "candidate_data_retention_days" => 365,
          "require_two_factor" => false
        }
      end
    end

    trait :enterprise do
      size_category { "enterprise" }
      settings do
        {
          "subscription_tier" => "enterprise",
          "subscription_ends_at" => 1.year.from_now.iso8601,
          "email_notifications" => true,
          "candidate_data_retention_days" => 1095,
          "require_two_factor" => true
        }
      end
    end

    trait :with_trial do
      settings do
        {
          "subscription_tier" => "starter",
          "trial_ends_at" => 15.days.from_now.iso8601,
          "email_notifications" => true,
          "candidate_data_retention_days" => 365,
          "require_two_factor" => false
        }
      end
    end

    trait :expired_trial do
      settings do
        {
          "subscription_tier" => "starter",
          "trial_ends_at" => 5.days.ago.iso8601,
          "email_notifications" => true,
          "candidate_data_retention_days" => 365,
          "require_two_factor" => false
        }
      end
    end
  end
end
