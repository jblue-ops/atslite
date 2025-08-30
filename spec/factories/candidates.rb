FactoryBot.define do
  factory :candidate do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.unique.email }
    phone { Faker::PhoneNumber.phone_number }
    location { "#{Faker::Address.city}, #{Faker::Address.state}" }
    linkedin_url { "https://linkedin.com/in/#{Faker::Internet.username.gsub(/[^a-zA-Z0-9\-]/, '')}" }
    github_url { "https://github.com/#{Faker::Internet.username.gsub(/[^a-zA-Z0-9\-]/, '')}" }
    portfolio_url { "https://#{Faker::Internet.domain_name}" }
    bio { Faker::Lorem.paragraphs(number: 2).join("\n\n") }
    years_of_experience { rand(0..15) }
    current_job_title { Faker::Job.title }
    current_company { Faker::Company.name }
    current_salary { rand(60_000..150_000) }
    current_salary_currency { ['USD', 'EUR', 'GBP', 'CAD'].sample }
    desired_salary_min { current_salary + rand(5_000..20_000) }
    desired_salary_max { desired_salary_min + rand(10_000..30_000) }
    desired_salary_currency { current_salary_currency }
    work_authorization { ['citizen', 'permanent_resident', 'work_visa', 'student_visa', 'needs_sponsorship'].sample }
    notice_period { ['immediate', 'two_weeks', 'one_month', 'two_months', 'three_months', 'other'].sample }
    resume_url { "https://#{Faker::Internet.domain_name}/resume.pdf" }
    resume_text { Faker::Lorem.paragraphs(number: 4).join("\n\n") }
    
    # Boolean preferences with realistic defaults
    marketing_consent { [true, false].sample }
    data_processing_consent { true } # Usually required
    available_for_interview { [true, false].sample }
    open_to_remote { [true, false].sample }
    willing_to_relocate { [true, false].sample }
    
    # JSONB fields with realistic data
    skills { ['Ruby', 'Rails', 'JavaScript', 'PostgreSQL', 'Git', 'HTML', 'CSS'].sample(rand(3..6)) }
    languages { { 'English' => 'native', ['Spanish', 'French', 'German', 'Mandarin'].sample => ['basic', 'conversational', 'fluent'].sample } }
    certifications { ['AWS Solutions Architect', 'Scrum Master', 'PMP', 'Google Analytics'].sample(rand(0..2)) }
    preferred_work_types { ['full_time', 'contract', 'part_time'].sample(rand(1..2)) }
    preferred_locations { [location, 'Remote', "#{Faker::Address.city}, #{Faker::Address.state}"].sample(rand(1..3)) }
    additional_documents { [] }
    
    # Timestamps for GDPR compliance
    marketing_consent_at { marketing_consent ? rand(30.days).seconds.ago : nil }
    data_processing_consent_at { data_processing_consent ? rand(30.days).seconds.ago : nil }
    last_activity_at { rand(7.days).seconds.ago }

    # Experience level traits
    trait :entry_level do
      years_of_experience { rand(0..2) }
      current_job_title { "Junior #{Faker::Job.title}" }
      current_salary { rand(45_000..65_000) }
      desired_salary_min { rand(50_000..70_000) }
      desired_salary_max { desired_salary_min + rand(10_000..20_000) }
      skills { ['JavaScript', 'HTML', 'CSS', 'Git'].sample(rand(2..4)) }
      certifications { [] }
    end
    
    trait :mid_level do
      years_of_experience { rand(3..7) }
      current_job_title { Faker::Job.title }
      current_salary { rand(70_000..110_000) }
      desired_salary_min { rand(80_000..120_000) }
      desired_salary_max { desired_salary_min + rand(15_000..30_000) }
      skills { ['Ruby', 'Rails', 'JavaScript', 'PostgreSQL', 'Git', 'Docker'].sample(rand(4..6)) }
      certifications { ['AWS Solutions Architect', 'Scrum Master'].sample(rand(0..1)) }
    end
    
    trait :senior_level do
      years_of_experience { rand(8..15) }
      current_job_title { "Senior #{Faker::Job.title}" }
      current_salary { rand(120_000..180_000) }
      desired_salary_min { rand(130_000..190_000) }
      desired_salary_max { desired_salary_min + rand(20_000..50_000) }
      skills { ['Ruby', 'Rails', 'JavaScript', 'PostgreSQL', 'AWS', 'Docker', 'Kubernetes', 'System Design'].sample(rand(6..8)) }
      certifications { ['AWS Solutions Architect', 'AWS DevOps Engineer', 'Scrum Master', 'PMP'].sample(rand(1..3)) }
    end

    trait :executive_level do
      years_of_experience { rand(15..25) }
      current_job_title { ['Director of Engineering', 'VP of Engineering', 'CTO'].sample }
      current_salary { rand(200_000..350_000) }
      desired_salary_min { rand(220_000..400_000) }
      desired_salary_max { desired_salary_min + rand(50_000..100_000) }
      skills { ['Leadership', 'Strategy', 'Architecture', 'Team Building', 'Ruby', 'JavaScript', 'AWS'].sample(rand(5..7)) }
      certifications { ['Executive Leadership', 'AWS Solutions Architect', 'PMP'].sample(rand(1..2)) }
    end

    # Work authorization traits
    trait :us_citizen do
      work_authorization { 'citizen' }
    end

    trait :permanent_resident do
      work_authorization { 'permanent_resident' }
    end
    
    trait :visa_required do
      work_authorization { 'needs_sponsorship' }
    end

    trait :h1b_holder do
      work_authorization { 'work_visa' }
    end

    trait :student_visa do
      work_authorization { 'student_visa' }
      years_of_experience { rand(0..2) }
    end

    # Availability traits
    trait :immediate_availability do
      notice_period { 'immediate' }
    end

    trait :standard_notice do
      notice_period { 'two_weeks' }
    end

    trait :long_notice do
      notice_period { ['two_months', 'three_months'].sample }
    end

    # Location preferences
    trait :remote_only do
      location { 'Remote' }
      open_to_remote { true }
      willing_to_relocate { false }
      preferred_locations { ['Remote'] }
    end

    trait :san_francisco do
      location { 'San Francisco, CA' }
      preferred_locations { ['San Francisco, CA', 'Remote'] }
    end

    trait :new_york do
      location { 'New York, NY' }
      preferred_locations { ['New York, NY', 'Remote'] }
    end

    trait :willing_to_relocate do
      willing_to_relocate { true }
      preferred_locations { ['San Francisco, CA', 'New York, NY', 'Seattle, WA', 'Austin, TX', 'Remote'] }
    end

    # Skill-specific traits
    trait :ruby_developer do
      skills { ['Ruby', 'Rails', 'RSpec', 'PostgreSQL', 'Git', 'HTML', 'CSS'] }
      current_job_title { 'Ruby Developer' }
      bio { 'Experienced Ruby developer with expertise in Rails applications and test-driven development.' }
    end

    trait :javascript_developer do
      skills { ['JavaScript', 'React', 'Node.js', 'HTML', 'CSS', 'Git'] }
      current_job_title { 'Frontend Developer' }
      bio { 'Frontend developer specializing in React applications and modern JavaScript.' }
    end

    trait :fullstack_developer do
      skills { ['JavaScript', 'Ruby', 'Rails', 'React', 'PostgreSQL', 'Git', 'Docker'] }
      current_job_title { 'Full Stack Developer' }
      bio { 'Full stack developer comfortable with both frontend and backend technologies.' }
    end

    trait :devops_engineer do
      skills { ['Docker', 'Kubernetes', 'AWS', 'CI/CD', 'Linux', 'Python', 'Terraform'] }
      current_job_title { 'DevOps Engineer' }
      bio { 'DevOps engineer focused on infrastructure automation and deployment pipelines.' }
    end

    trait :data_scientist do
      skills { ['Python', 'R', 'SQL', 'Machine Learning', 'TensorFlow', 'Pandas', 'Statistics'] }
      current_job_title { 'Data Scientist' }
      bio { 'Data scientist with expertise in machine learning and statistical analysis.' }
      certifications { ['AWS Machine Learning', 'Google Cloud Professional Data Engineer'] }
    end

    trait :product_manager do
      skills { ['Product Strategy', 'Data Analysis', 'User Research', 'A/B Testing', 'Figma'] }
      current_job_title { 'Product Manager' }
      bio { 'Product manager with experience leading cross-functional teams and data-driven product decisions.' }
      certifications { ['Certified Scrum Product Owner', 'Google Analytics'] }
    end

    trait :designer do
      skills { ['Figma', 'Sketch', 'Adobe Creative Suite', 'User Research', 'Prototyping', 'Design Systems'] }
      current_job_title { 'UX/UI Designer' }
      bio { 'UX/UI designer passionate about creating user-centered design solutions.' }
      portfolio_url { "https://#{first_name.downcase}#{last_name.downcase}.design" }
    end

    # Language traits
    trait :multilingual do
      languages { {
        'English' => 'native',
        'Spanish' => 'fluent',
        'French' => 'conversational'
      } }
    end

    trait :english_only do
      languages { { 'English' => 'native' } }
    end

    # Salary traits
    trait :high_earner do
      current_salary { rand(150_000..250_000) }
      desired_salary_min { rand(170_000..280_000) }
      desired_salary_max { desired_salary_min + rand(30_000..70_000) }
    end

    trait :entry_salary do
      current_salary { rand(45_000..65_000) }
      desired_salary_min { rand(50_000..70_000) }
      desired_salary_max { desired_salary_min + rand(10_000..20_000) }
    end

    trait :flexible_salary do
      desired_salary_min { nil }
      desired_salary_max { nil }
      current_salary { nil }
    end

    # GDPR and consent traits
    trait :gdpr_compliant do
      marketing_consent { true }
      marketing_consent_at { 1.day.ago }
      data_processing_consent { true }
      data_processing_consent_at { 1.day.ago }
    end

    trait :marketing_opted_out do
      marketing_consent { false }
      marketing_consent_at { nil }
      data_processing_consent { true }
      data_processing_consent_at { 1.day.ago }
    end

    trait :scheduled_for_deletion do
      gdpr_delete_after { 1.week.from_now }
    end

    trait :due_for_deletion do
      gdpr_delete_after { 1.day.ago }
    end

    # Activity traits
    trait :recently_active do
      last_activity_at { 1.day.ago }
    end

    trait :inactive do
      last_activity_at { 2.months.ago }
    end

    trait :new_candidate do
      created_at { 1.day.ago }
      last_activity_at { 1.day.ago }
    end

    # Comprehensive profile trait
    trait :complete_profile do
      bio { 'Experienced software engineer with a passion for building scalable applications.' }
      linkedin_url { "https://linkedin.com/in/#{first_name.downcase}-#{last_name.downcase}" }
      github_url { "https://github.com/#{first_name.downcase}#{last_name.downcase}" }
      portfolio_url { "https://#{first_name.downcase}#{last_name.downcase}.dev" }
      resume_url { "https://example.com/resumes/#{first_name.downcase}-#{last_name.downcase}.pdf" }
      skills { ['Ruby', 'Rails', 'JavaScript', 'React', 'PostgreSQL', 'Docker', 'AWS'] }
      certifications { ['AWS Solutions Architect', 'Scrum Master'] }
      languages { { 'English' => 'native', 'Spanish' => 'fluent' } }
      preferred_work_types { ['full_time', 'contract'] }
      preferred_locations { [location, 'Remote'] }
      marketing_consent { true }
      marketing_consent_at { 1.week.ago }
      data_processing_consent { true }
      data_processing_consent_at { 1.week.ago }
    end

    # Minimal profile trait
    trait :minimal_profile do
      bio { nil }
      linkedin_url { nil }
      github_url { nil }
      portfolio_url { nil }
      resume_url { nil }
      skills { [] }
      certifications { [] }
      languages { { 'English' => 'native' } }
      preferred_work_types { [] }
      preferred_locations { [] }
      years_of_experience { nil }
      current_salary { nil }
      desired_salary_min { nil }
      desired_salary_max { nil }
    end

    # Application-related traits
    trait :with_applications do
      transient do
        applications_count { 3 }
      end
      
      after(:create) do |candidate, evaluator|
        create_list(:application, evaluator.applications_count, candidate: candidate)
      end
    end

    trait :active_job_seeker do
      available_for_interview { true }
      notice_period { ['immediate', 'two_weeks'].sample }
      last_activity_at { rand(3.days).seconds.ago }
      with_applications
    end

    trait :passive_candidate do
      available_for_interview { false }
      notice_period { ['two_months', 'three_months', 'other'].sample }
      last_activity_at { rand(30.days).seconds.ago }
    end

    # Soft delete trait
    trait :deleted do
      deleted_at { 1.week.ago }
    end

    # Industry-specific traits
    trait :startup_experience do
      bio { 'Experienced engineer with startup background, comfortable with ambiguity and rapid iteration.' }
      skills { skills + ['Startup Experience', 'Growth Mindset', 'Scrappy'] }
      preferred_work_types { ['full_time', 'contract'] }
      willing_to_relocate { true }
      open_to_remote { true }
    end

    trait :enterprise_experience do
      bio { 'Senior engineer with enterprise software development experience and large-scale system design.' }
      skills { skills + ['Enterprise Architecture', 'Microservices', 'System Design'] }
      certifications { certifications + ['Enterprise Architecture'] }
      current_company { ['Microsoft', 'Google', 'Amazon', 'IBM', 'Oracle'].sample }
    end
  end
end