FactoryBot.define do
  factory :candidate do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.unique.email }
    phone { Faker::PhoneNumber.phone_number }
    location { "#{Faker::Address.city}, #{Faker::Address.state}" }
    linkedin_url { "https://linkedin.com/in/#{Faker::Internet.username}" }
    github_url { "https://github.com/#{Faker::Internet.username}" }
    portfolio_url { "https://#{Faker::Internet.domain_name}" }
    summary { Faker::Lorem.paragraphs(number: 2).join("\n\n") }
    experience_years { rand(0..15) }
    current_title { Faker::Job.title }
    current_company { Faker::Company.name }
    desired_salary { rand(60_000..150_000) }
    availability { %w[immediate 2_weeks 1_month 2_months].sample }
    willing_to_relocate { [true, false].sample }
    work_authorization { %w[us_citizen permanent_resident h1b opt student_visa].sample }

    trait :with_resume do
      after(:build) do |candidate|
        candidate.resume.attach(
          io: File.open(Rails.root.join("spec", "fixtures", "files", "sample_resume.pdf")),
          filename: "resume.pdf",
          content_type: "application/pdf"
        )
      end
    end

    trait :with_cover_letter do
      after(:build) do |candidate|
        candidate.cover_letter.attach(
          io: File.open(Rails.root.join("spec", "fixtures", "files", "cover_letter.pdf")),
          filename: "cover_letter.pdf",
          content_type: "application/pdf"
        )
      end
    end

    trait :with_portfolio do
      after(:build) do |candidate|
        3.times do |i|
          candidate.portfolio_files.attach(
            io: File.open(Rails.root.join("spec", "fixtures", "files", "portfolio_sample.pdf")),
            filename: "portfolio_#{i + 1}.pdf",
            content_type: "application/pdf"
          )
        end
      end
    end

    trait :with_skills do
      after(:create) do |candidate|
        skills = ["Ruby", "Rails", "JavaScript", "React", "Node.js", "Python", "PostgreSQL", "AWS", "Docker", "Git"]
        candidate.skill_list.add(*skills.sample(rand(3..6)))
        candidate.save
      end
    end

    trait :entry_level do
      experience_years { rand(0..2) }
      current_title { "Junior #{Faker::Job.title}" }
      desired_salary { rand(50_000..70_000) }
    end

    trait :mid_level do
      experience_years { rand(3..7) }
      current_title { Faker::Job.title }
      desired_salary { rand(80_000..120_000) }
    end

    trait :senior_level do
      experience_years { rand(8..15) }
      current_title { "Senior #{Faker::Job.title}" }
      desired_salary { rand(130_000..180_000) }
    end

    trait :remote_only do
      location { "Remote" }
      willing_to_relocate { false }
      remote_preference { "remote_only" }
    end

    trait :visa_required do
      work_authorization { "h1b" }
    end

    trait :immediate_availability do
      availability { "immediate" }
      employment_status { "unemployed" }
    end

    trait :currently_employed do
      employment_status { "employed" }
      availability { "2_weeks" }
    end

    trait :with_education do
      after(:create) do |candidate|
        create_list(:education, rand(1..3), candidate: candidate)
      end
    end

    trait :with_work_experience do
      after(:create) do |candidate|
        create_list(:work_experience, rand(2..5), candidate: candidate)
      end
    end

    trait :with_applications do
      transient do
        applications_count { 3 }
      end

      after(:create) do |candidate, evaluator|
        create_list(:application, evaluator.applications_count, candidate: candidate)
      end
    end

    trait :blacklisted do
      blacklisted { true }
      blacklisted_reason { "Multiple no-shows for interviews" }
      blacklisted_at { 1.week.ago }
    end

    trait :with_references do
      after(:create) do |candidate|
        create_list(:reference, 2, candidate: candidate)
      end
    end

    # Source tracking
    trait :from_job_board do
      source { "indeed" }
      source_details { { platform: "indeed", campaign: "software_engineer_2023" } }
    end

    trait :from_referral do
      source { "referral" }
      referred_by { association :user }
    end

    trait :from_linkedin do
      source { "linkedin" }
      linkedin_url { "https://linkedin.com/in/#{Faker::Internet.username}" }
    end

    # Diversity and inclusion tracking
    trait :with_diversity_info do
      gender { %w[male female non_binary prefer_not_to_say].sample }
      ethnicity { %w[asian black hispanic white other prefer_not_to_say].sample }
      veteran_status { [true, false].sample }
    end
  end

  factory :education do
    candidate
    degree { ["High School", "Associate", "Bachelor", "Master", "PhD"].sample }
    field_of_study { Faker::Educator.subject }
    institution { Faker::Educator.university }
    start_year { rand(2000..2020) }
    end_year { start_year + rand(2..6) }
    gpa { rand(2.5..4.0).round(2) }

    trait :bachelor_degree do
      degree { "Bachelor" }
      field_of_study { "Computer Science" }
    end

    trait :current_student do
      end_year { nil }
      current { true }
    end
  end

  factory :work_experience do
    candidate
    title { Faker::Job.title }
    company { Faker::Company.name }
    location { "#{Faker::Address.city}, #{Faker::Address.state}" }
    start_date { rand(5.years.ago..2.years.ago) }
    end_date { start_date + rand(6.months..2.years) }
    description { Faker::Lorem.paragraphs(number: 2).join("\n") }

    trait :current_job do
      end_date { nil }
      current { true }
    end

    trait :software_engineer do
      title { "Software Engineer" }
      description do
        "• Developed and maintained web applications using Ruby on Rails\n" +
          "• Collaborated with cross-functional teams to deliver features\n" +
          "• Implemented automated testing and CI/CD pipelines"
      end
    end
  end

  factory :reference do
    candidate
    name { Faker::Name.name }
    title { Faker::Job.title }
    company { Faker::Company.name }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.phone_number }
    relationship { %w[manager colleague client mentor].sample }

    trait :manager_reference do
      relationship { "manager" }
      title { "Engineering Manager" }
    end

    trait :contacted do
      contacted_at { 1.week.ago }
      response_received { true }
      feedback { Faker::Lorem.paragraph }
    end
  end
end
