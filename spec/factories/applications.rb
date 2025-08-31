# frozen_string_literal: true

FactoryBot.define do
  factory :application do
    job
    candidate
    current_stage { "applied" }
    applied_at { Time.current }
    source { "direct" }
    cover_letter_text { Faker::Lorem.paragraphs(number: 2).join("\n\n") }

    # Ensure the candidate and job belong to the same company context
    after(:build) do |application|
      if application.job.present? && application.candidate.present?
        # Add any company-specific logic here if needed
      end
    end

    trait :screening do
      current_stage { "screening" }
      after(:create) do |application|
        create(:stage_transition, application: application,
                                  from_stage: "applied", to_stage: "screening",
                                  transitioned_at: 1.day.ago)
      end
    end

    trait :interviewing do
      current_stage { "interview" }
      after(:create) do |application|
        create(:stage_transition, application: application,
                                  from_stage: "applied", to_stage: "screening",
                                  transitioned_at: 3.days.ago)
        create(:stage_transition, application: application,
                                  from_stage: "screening", to_stage: "interview",
                                  transitioned_at: 1.day.ago)
      end
    end

    trait :technical_interview do
      current_stage { "technical" }
      after(:create) do |application|
        create(:stage_transition, application: application,
                                  from_stage: "applied", to_stage: "screening",
                                  transitioned_at: 5.days.ago)
        create(:stage_transition, application: application,
                                  from_stage: "screening", to_stage: "technical",
                                  transitioned_at: 2.days.ago)
      end
    end

    trait :final_interview do
      current_stage { "final" }
      after(:create) do |application|
        %w[screening technical].each_with_index do |stage, index|
          create(:stage_transition, application: application,
                                    from_stage: index == 0 ? "applied" : "screening",
                                    to_stage: stage,
                                    transitioned_at: (5 - (index * 2)).days.ago)
        end
        create(:stage_transition, application: application,
                                  from_stage: "technical", to_stage: "final",
                                  transitioned_at: 1.day.ago)
      end
    end

    trait :offered do
      current_stage { "offer" }
      offer_extended_at { 1.day.ago }
      offer_expires_at { 1.week.from_now }
      after(:create) do |application|
        create(:offer, application: application)
      end
    end

    trait :hired do
      current_stage { "hired" }
      hired_at { 1.day.ago }
      start_date { 2.weeks.from_now }
    end

    trait :rejected do
      current_stage { "rejected" }
      rejected_at { 1.day.ago }
      rejection_reason { %w[not_qualified cultural_fit compensation other].sample }
      after(:create) do |application|
        create(:rejection, application: application)
      end
    end

    trait :withdrawn do
      current_stage { "withdrawn" }
      withdrawn_at { 1.day.ago }
      withdrawal_reason { "accepted_other_offer" }
    end

    trait :with_resume do
      after(:build) do |application|
        unless application.candidate.resume.attached?
          application.candidate.resume.attach(
            io: Rails.root.join("spec", "fixtures", "files", "sample_resume.pdf").open,
            filename: "resume.pdf",
            content_type: "application/pdf"
          )
        end
      end
    end

    trait :with_cover_letter_file do
      after(:build) do |application|
        application.cover_letter_file.attach(
          io: Rails.root.join("spec", "fixtures", "files", "cover_letter.pdf").open,
          filename: "cover_letter.pdf",
          content_type: "application/pdf"
        )
      end
    end

    trait :with_interviews do
      transient do
        interviews_count { 2 }
      end

      after(:create) do |application, evaluator|
        create_list(:interview, evaluator.interviews_count, application: application)
      end
    end

    trait :with_feedback do
      after(:create) do |application|
        create_list(:feedback, 2, application: application)
      end
    end

    trait :high_priority do
      priority { "high" }
      priority_reason { "Strong technical background and cultural fit" }
    end

    trait :flagged do
      flagged { true }
      flag_reason { "Needs additional review" }
      flagged_by { association :user }
    end

    # Source-specific traits
    trait :from_referral do
      source { "referral" }
      referrer { association :user }
      referrer_bonus_eligible { true }
    end

    trait :from_job_board do
      source { "indeed" }
      source_campaign { "software_engineer_q4_2023" }
    end

    trait :from_career_page do
      source { "career_page" }
    end

    trait :from_linkedin do
      source { "linkedin" }
    end

    # Rating and scoring
    trait :highly_rated do
      overall_rating { rand(4.0..5.0).round(1) }
    end

    trait :poorly_rated do
      overall_rating { rand(1.0..2.5).round(1) }
    end

    # Communication preferences
    trait :prefers_email do
      communication_preference { "email" }
    end

    trait :prefers_phone do
      communication_preference { "phone" }
    end

    # Salary expectations
    trait :salary_match do
      expected_salary { job.salary_min + rand(0..(job.salary_max - job.salary_min)) }
    end

    trait :salary_too_high do
      expected_salary { job.salary_max + rand(10_000..30_000) }
    end

    # Location preferences
    trait :local_candidate do
      candidate { association :candidate, location: job.location }
    end

    trait :remote_candidate do
      candidate { association :candidate, location: "Remote" }
    end
  end

  factory :stage_transition do
    application
    from_stage { "applied" }
    to_stage { "screening" }
    transitioned_at { Time.current }
    transitioned_by { association :user }
    notes { Faker::Lorem.sentence }

    trait :with_reason do
      transition_reason { "Candidate showed strong technical skills in initial screening" }
    end

    trait :automated do
      automated { true }
      transitioned_by { nil }
    end
  end

  factory :offer do
    application
    salary { application.job.salary_max }
    currency { "USD" }
    employment_type { application.job.employment_type }
    start_date { 2.weeks.from_now }
    benefits { ["Health Insurance", "Dental", "Vision", "401k", "PTO"] }
    equity_percentage { rand(0.01..0.5).round(3) if rand < 0.3 } # 30% chance of equity
    signing_bonus { rand(5_000..25_000) if rand < 0.2 } # 20% chance of signing bonus
    remote_work_allowed { [true, false].sample }
    relocation_assistance { rand(5_000..15_000) if rand < 0.1 } # 10% chance

    status { "pending" }
    expires_at { 1.week.from_now }
    created_by { association :user, :hiring_manager }

    trait :accepted do
      status { "accepted" }
      accepted_at { 1.day.ago }
    end

    trait :rejected do
      status { "rejected" }
      rejected_at { 1.day.ago }
      rejection_reason { "salary_too_low" }
    end

    trait :expired do
      status { "expired" }
      expires_at { 1.day.ago }
    end

    trait :with_equity do
      equity_percentage { rand(0.01..0.5).round(3) }
      vesting_schedule { "4 years, 1 year cliff" }
    end

    trait :with_signing_bonus do
      signing_bonus { rand(10_000..50_000) }
    end

    trait :remote_position do
      remote_work_allowed { true }
      office_days_required { 0 }
    end

    trait :hybrid_position do
      remote_work_allowed { true }
      office_days_required { 3 }
    end
  end

  factory :rejection do
    application
    rejected_by { association :user }
    reason { %w[not_qualified cultural_fit compensation_mismatch position_filled other].sample }
    feedback { Faker::Lorem.paragraph }
    rejected_at { Time.current }

    trait :automated do
      automated { true }
      reason { "failed_assessment" }
    end

    trait :with_detailed_feedback do
      feedback do
        "Thank you for your interest in our company. After careful consideration, " \
          "we have decided to move forward with other candidates whose experience " \
          "more closely aligns with our current needs. We encourage you to apply " \
          "for future positions that match your background."
      end
    end
  end

  factory :feedback do
    application
    reviewer { association :user }
    overall_rating { rand(1..5) }
    technical_rating { rand(1..5) }
    communication_rating { rand(1..5) }
    cultural_fit_rating { rand(1..5) }
    comments { Faker::Lorem.paragraphs(number: 2).join("\n\n") }
    recommend_hire { [true, false].sample }

    trait :positive do
      overall_rating { rand(4..5) }
      technical_rating { rand(4..5) }
      communication_rating { rand(4..5) }
      cultural_fit_rating { rand(4..5) }
      recommend_hire { true }
      comments { "Strong candidate with excellent technical skills and great communication." }
    end

    trait :negative do
      overall_rating { rand(1..2) }
      technical_rating { rand(1..2) }
      recommend_hire { false }
      comments { "Candidate lacks the required technical skills for this position." }
    end

    trait :from_phone_screen do
      interview_type { "phone_screen" }
    end

    trait :from_technical_interview do
      interview_type { "technical" }
      technical_rating { rand(3..5) }
    end
  end
end
