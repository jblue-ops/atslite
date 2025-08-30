FactoryBot.define do
  factory :job do
    company
    title { Faker::Job.title }
    description { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    requirements { Faker::Lorem.paragraphs(number: 2).join("\n\n") }
    location { "#{Faker::Address.city}, #{Faker::Address.state}" }
    employment_type { ['full_time', 'part_time', 'contract', 'internship', 'temporary'].sample }
    experience_level { ['entry', 'mid', 'senior', 'executive'].sample }
    work_location_type { ['on_site', 'hybrid', 'remote'].sample }
    urgency { ['low', 'medium', 'high', 'urgent'].sample }
    salary_period { ['hourly', 'daily', 'weekly', 'monthly', 'annually'].sample }
    salary_min { rand(50_000..120_000) }
    salary_max { salary_min + rand(20_000..80_000) }
    salary_currency { ['USD', 'EUR', 'GBP', 'CAD'].sample }
    status { 'draft' }
    hiring_manager { association :user, :recruiter, company: company }
    openings_count { rand(1..5) }
    active { true }
    confidential { [true, false].sample }
    remote_work_eligible { [true, false].sample }
    required_skills { ['Ruby', 'Rails', 'JavaScript', 'PostgreSQL', 'Git'].sample(rand(2..4)) }
    nice_to_have_skills { ['Docker', 'AWS', 'React', 'Node.js', 'Redis'].sample(rand(1..3)) }
    pipeline_stages { ['Application', 'Phone Screen', 'Technical Interview', 'Final Interview', 'Offer', 'Hired', 'Rejected'] }
    
    trait :published do
      status { 'published' }
      posted_at { 1.day.ago }
      active { true }
    end
    
    trait :closed do
      status { 'closed' }
      active { false }
    end
    
    trait :paused do
      status { 'paused' }
    end

    trait :archived do
      status { 'archived' }
      active { false }
    end
    
    trait :remote do
      location { 'Remote' }
      work_location_type { 'remote' }
      remote_work_eligible { true }
    end

    trait :hybrid do
      work_location_type { 'hybrid' }
      remote_work_eligible { true }
    end

    trait :on_site do
      work_location_type { 'on_site' }
      remote_work_eligible { false }
    end
    
    trait :senior_role do
      experience_level { 'senior' }
      salary_min { 120_000 }
      salary_max { 180_000 }
      salary_currency { 'USD' }
      salary_period { 'annually' }
      title { "Senior #{Faker::Job.title}" }
      required_skills { ['Ruby', 'Rails', 'PostgreSQL', 'JavaScript', 'Git'] }
      nice_to_have_skills { ['Docker', 'AWS', 'Redis', 'Elasticsearch'] }
    end
    
    trait :entry_level do
      experience_level { 'entry' }
      salary_min { 50_000 }
      salary_max { 70_000 }
      salary_currency { 'USD' }
      salary_period { 'annually' }
      title { "Junior #{Faker::Job.title}" }
      required_skills { ['JavaScript', 'HTML', 'CSS'] }
      nice_to_have_skills { ['React', 'Node.js'] }
    end

    trait :executive_role do
      experience_level { 'executive' }
      salary_min { 200_000 }
      salary_max { 300_000 }
      salary_currency { 'USD' }
      salary_period { 'annually' }
      title { ['CTO', 'VP of Engineering', 'Director of Product'].sample }
      urgency { 'high' }
      confidential { true }
    end
    
    trait :contract do
      employment_type { 'contract' }
      salary_period { 'hourly' }
      salary_min { 50 }
      salary_max { 125 }
    end

    trait :internship do
      employment_type { 'internship' }
      experience_level { 'entry' }
      salary_period { 'hourly' }
      salary_min { 15 }
      salary_max { 25 }
    end
    
    trait :with_comprehensive_skills do
      required_skills { ['Ruby', 'Rails', 'JavaScript', 'PostgreSQL', 'Git', 'HTML', 'CSS'] }
      nice_to_have_skills { ['React', 'Vue.js', 'Docker', 'AWS', 'Redis', 'Elasticsearch', 'GraphQL'] }
    end

    trait :frontend_focused do
      title { 'Frontend Developer' }
      required_skills { ['JavaScript', 'HTML', 'CSS', 'React'] }
      nice_to_have_skills { ['TypeScript', 'Vue.js', 'Webpack', 'SASS'] }
    end

    trait :backend_focused do
      title { 'Backend Developer' }
      required_skills { ['Ruby', 'Rails', 'PostgreSQL', 'API Development'] }
      nice_to_have_skills { ['Redis', 'Elasticsearch', 'Docker', 'AWS'] }
    end

    trait :fullstack do
      title { 'Full Stack Developer' }
      required_skills { ['JavaScript', 'Ruby', 'Rails', 'React', 'PostgreSQL'] }
      nice_to_have_skills { ['Node.js', 'Docker', 'AWS', 'TypeScript'] }
    end
    
    trait :with_applications do
      transient do
        applications_count { 5 }
      end
      
      after(:create) do |job, evaluator|
        create_list(:application, evaluator.applications_count, job: job)
      end
    end

    trait :popular do
      after(:create) do |job|
        create_list(:application, 25, job: job)
      end
    end
    
    trait :urgent do
      urgency { 'urgent' }
      application_deadline { 1.week.from_now }
      target_start_date { 2.weeks.from_now }
    end

    trait :confidential_role do
      confidential { true }
      title { 'Confidential Position' }
      description { 'Details will be shared with qualified candidates.' }
    end
    
    trait :with_tech_pipeline do
      pipeline_stages { ['Application', 'Phone Screen', 'Coding Challenge', 'Technical Interview', 'System Design', 'Team Interview', 'Offer', 'Hired', 'Rejected'] }
    end

    trait :with_sales_pipeline do
      pipeline_stages { ['Application', 'Phone Screen', 'Case Study', 'Role Play', 'Final Interview', 'Offer', 'Hired', 'Rejected'] }
    end

    trait :with_executive_pipeline do
      pipeline_stages { ['Application', 'Initial Screen', 'Executive Interview', 'Board Presentation', 'Reference Check', 'Offer', 'Hired', 'Rejected'] }
    end
    
    # Salary variations
    trait :hourly_rate do
      salary_period { 'hourly' }
      salary_min { 25 }
      salary_max { 75 }
    end

    trait :high_salary do
      salary_min { 150_000 }
      salary_max { 200_000 }
      salary_currency { 'USD' }
      salary_period { 'annually' }
    end

    trait :startup do
      salary_min { 80_000 }
      salary_max { 120_000 }
      referral_bonus_amount { '$5,000' }
      required_skills { ['Ruby', 'Rails', 'JavaScript', 'React'] }
      nice_to_have_skills { ['Startup Experience', 'Scrappy', 'Growth Mindset'] }
    end
    
    # Industry-specific job templates
    trait :software_engineer do
      title { 'Software Engineer' }
      department_id { 1 } # Engineering
      experience_level { 'mid' }
      employment_type { 'full_time' }
      required_skills { ['Ruby', 'Rails', 'JavaScript', 'PostgreSQL', 'Git'] }
      nice_to_have_skills { ['React', 'Docker', 'AWS'] }
      requirements { 
        "• 3+ years of experience with Ruby on Rails\n" +
        "• Strong understanding of web technologies\n" +
        "• Experience with SQL databases\n" +
        "• Knowledge of version control (Git)"
      }
    end
    
    trait :product_manager do
      title { 'Product Manager' }
      department_id { 2 } # Product
      experience_level { 'senior' }
      employment_type { 'full_time' }
      required_skills { ['Product Strategy', 'Data Analysis', 'User Research'] }
      nice_to_have_skills { ['SQL', 'A/B Testing', 'Figma'] }
      requirements {
        "• 5+ years of product management experience\n" +
        "• Strong analytical and communication skills\n" +
        "• Experience with agile methodologies\n" +
        "• Technical background preferred"
      }
    end
    
    trait :sales_rep do
      title { 'Sales Representative' }
      department_id { 3 } # Sales
      experience_level { 'mid' }
      employment_type { 'full_time' }
      required_skills { ['Sales', 'CRM', 'Lead Generation'] }
      nice_to_have_skills { ['SaaS Experience', 'Salesforce', 'Cold Calling'] }
    end

    trait :data_scientist do
      title { 'Data Scientist' }
      department_id { 4 } # Data
      experience_level { 'senior' }
      required_skills { ['Python', 'SQL', 'Machine Learning', 'Statistics'] }
      nice_to_have_skills { ['TensorFlow', 'PyTorch', 'AWS', 'Spark'] }
    end

    trait :designer do
      title { 'UX/UI Designer' }
      department_id { 5 } # Design
      experience_level { 'mid' }
      required_skills { ['Figma', 'User Research', 'Prototyping', 'Design Systems'] }
      nice_to_have_skills { ['Sketch', 'Adobe Creative Suite', 'HTML/CSS'] }
    end

    # Date-based traits
    trait :deadline_soon do
      application_deadline { 3.days.from_now }
    end

    trait :recent_posting do
      posted_at { 2.days.ago }
      status { 'published' }
    end

    trait :old_posting do
      posted_at { 2.months.ago }
      status { 'published' }
    end

    # Location-based traits
    trait :san_francisco do
      location { 'San Francisco, CA' }
      work_location_type { 'hybrid' }
    end

    trait :new_york do
      location { 'New York, NY' }
      work_location_type { 'hybrid' }
    end

    trait :remote_only do
      location { 'Remote' }
      work_location_type { 'remote' }
      remote_work_eligible { true }
    end
  end
end