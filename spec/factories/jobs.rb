FactoryBot.define do
  factory :job do
    company
    title { Faker::Job.title }
    description { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    requirements { Faker::Lorem.paragraphs(number: 2).join("\n\n") }
    location { "#{Faker::Address.city}, #{Faker::Address.state}" }
    employment_type { %w[full_time part_time contract internship].sample }
    experience_level { %w[entry mid senior lead executive].sample }
    salary_min { rand(50_000..120_000) }
    salary_max { salary_min + rand(20_000..80_000) }
    salary_currency { "USD" }
    remote_ok { [true, false].sample }
    status { "draft" }
    posted_by { association :user, :recruiter, company: company }
    department { "Engineering" }

    # Default pipeline stages
    after(:create) do |job|
      ["Applied", "Phone Screen", "Technical Interview", "Final Interview", "Offer", "Hired", "Rejected"].each_with_index do |stage, index|
        create(:pipeline_stage, job: job, name: stage, position: index + 1)
      end
    end

    trait :active do
      status { "active" }
      published_at { 1.day.ago }
    end

    trait :closed do
      status { "closed" }
      closed_at { 1.day.ago }
    end

    trait :paused do
      status { "paused" }
      paused_at { 1.day.ago }
    end

    trait :remote do
      location { "Remote" }
      remote_ok { true }
    end

    trait :senior_role do
      experience_level { "senior" }
      salary_min { 120_000 }
      salary_max { 180_000 }
      title { "Senior #{Faker::Job.title}" }
    end

    trait :entry_level do
      experience_level { "entry" }
      salary_min { 50_000 }
      salary_max { 70_000 }
      title { "Junior #{Faker::Job.title}" }
    end

    trait :contract do
      employment_type { "contract" }
      contract_duration { "6 months" }
    end

    trait :with_skills do
      after(:create) do |job|
        skills = %w[Ruby Rails JavaScript React PostgreSQL AWS]
        job.skill_list.add(*skills.sample(3))
        job.save
      end
    end

    trait :with_applications do
      transient do
        applications_count { 5 }
      end

      after(:create) do |job, evaluator|
        create_list(:application, evaluator.applications_count, job: job)
      end
    end

    trait :urgent do
      priority { "high" }
      filled_by_date { 2.weeks.from_now }
    end

    trait :with_custom_pipeline do
      after(:create) do |job|
        job.pipeline_stages.destroy_all
        ["Applied", "Coding Challenge", "Technical Screen", "System Design", "Culture Fit", "Offer"].each_with_index do |stage, index|
          create(:pipeline_stage, job: job, name: stage, position: index + 1)
        end
      end
    end

    # Job board specific traits
    trait :posted_to_job_boards do
      job_board_postings { %w[indeed linkedin glassdoor] }
      external_posting_urls do
        {
          "indeed" => "https://indeed.com/job/123",
          "linkedin" => "https://linkedin.com/job/456"
        }
      end
    end

    # Industry-specific job templates
    trait :software_engineer do
      title { "Software Engineer" }
      department { "Engineering" }
      with_skills
      requirements do
        "• 3+ years of experience with Ruby on Rails\n" +
          "• Strong understanding of web technologies\n" +
          "• Experience with SQL databases\n" +
          "• Knowledge of version control (Git)"
      end
    end

    trait :product_manager do
      title { "Product Manager" }
      department { "Product" }
      requirements do
        "• 5+ years of product management experience\n" +
          "• Strong analytical and communication skills\n" +
          "• Experience with agile methodologies\n" +
          "• Technical background preferred"
      end
    end

    trait :sales_rep do
      title { "Sales Representative" }
      department { "Sales" }
      salary_structure { "base_plus_commission" }
      commission_rate { 0.05 }
    end
  end

  factory :pipeline_stage do
    job
    name { "Applied" }
    position { 1 }
    description { "Initial application stage" }

    trait :screening do
      name { "Phone Screen" }
      position { 2 }
      description { "Initial phone screening with recruiter" }
    end

    trait :interview do
      name { "Technical Interview" }
      position { 3 }
      description { "Technical interview with team members" }
    end

    trait :final_stage do
      name { "Offer" }
      position { 5 }
      description { "Offer extended to candidate" }
    end
  end

  factory :job_posting do
    job
    platform { "indeed" }
    external_id { Faker::Alphanumeric.alphanumeric(number: 10) }
    posted_at { 1.day.ago }
    status { "active" }
    url { "https://indeed.com/job/#{external_id}" }

    trait :linkedin do
      platform { "linkedin" }
      url { "https://linkedin.com/job/#{external_id}" }
    end

    trait :expired do
      status { "expired" }
      expires_at { 1.day.ago }
    end
  end
end
