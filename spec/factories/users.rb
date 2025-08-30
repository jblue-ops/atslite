# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    organization
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    sequence(:email) { |n| "user#{n}@example.com" }
    phone { "555-#{rand(100..999)}-#{rand(1000..9999)}" }
    role { "recruiter" }
    password { "StrongPass1!" }
    password_confirmation { "StrongPass1!" }
    active { true }
    time_zone { "UTC" }
    confirmed_at { Time.current }

    trait :admin do
      role { "admin" }
    end

    trait :hiring_manager do
      role { "hiring_manager" }
    end

    trait :recruiter do
      role { "recruiter" }
    end

    trait :interviewer do
      role { "interviewer" }
    end

    trait :coordinator do
      role { "coordinator" }
    end

    trait :inactive do
      active { false }
    end

    trait :unconfirmed do
      confirmed_at { nil }
      confirmation_sent_at { Time.current }
    end

    trait :locked do
      locked_at { 1.hour.ago }
      failed_attempts { 5 }
    end

    trait :with_invitation do
      invited_by { association :user, :admin }
      invited_at { 1.day.ago }
    end

    trait :recent_activity do
      last_sign_in_at { 1.hour.ago }
      current_sign_in_at { Time.current }
      sign_in_count { 5 }
    end

    # Location-based traits
    trait :remote do
      time_zone { "America/Los_Angeles" }
    end

    trait :east_coast do
      time_zone { "America/New_York" }
    end

    trait :central do
      time_zone { "America/Chicago" }
    end

    # Permission traits
    trait :with_custom_permissions do
      after(:create) do |user|
        user.permissions = %w[custom_permission_1 custom_permission_2]
        user.save!
      end
    end

    factory :admin_user, traits: [:admin]
    factory :hiring_manager_user, traits: [:hiring_manager]
    factory :recruiter_user, traits: [:recruiter]
    factory :interviewer_user, traits: [:interviewer]
    factory :coordinator_user, traits: [:coordinator]
  end
end
