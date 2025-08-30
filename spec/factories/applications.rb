FactoryBot.define do
  factory :application do
    company
    job { association :job, company: company }
    candidate
    status { 'applied' }
    applied_at { Time.current }
    source { 'direct' }
    cover_letter { Faker::Lorem.paragraphs(number: 2).join("\n\n") }
    metadata { { 'source_campaign' => 'general_hiring', 'application_method' => 'web_form' } }
    
    # Ensure the candidate and job belong to the same company context
    after(:build) do |application|
      if application.job.present? && application.candidate.present?
        # Add any company-specific logic here if needed
      end
    end
    
    trait :screening do
      status { 'screening' }
      stage_changed_at { 1.day.ago }
    end
    
    trait :phone_interview do
      status { 'phone_interview' }
      stage_changed_at { 1.day.ago }
    end
    
    trait :technical_interview do
      status { 'technical_interview' }
      stage_changed_at { 2.days.ago }
    end
    
    trait :final_interview do
      status { 'final_interview' }
      stage_changed_at { 1.day.ago }
    end
    
    trait :offered do
      status { 'offer' }
      stage_changed_at { 1.day.ago }
      salary_offered { 7500000 } # $75,000 in cents
    end
    
    trait :accepted do
      status { 'accepted' }
      stage_changed_at { 1.day.ago }
      salary_offered { 8000000 } # $80,000 in cents
    end
    
    trait :rejected do
      status { 'rejected' }
      rejected_at { 1.day.ago }
      stage_changed_at { 1.day.ago }
      rejection_reason { ['not qualified', 'cultural fit', 'compensation mismatch', 'other'].sample }
    end
    
    trait :withdrawn do
      status { 'withdrawn' }
      stage_changed_at { 1.day.ago }
      rejection_reason { 'accepted other offer' }
    end
    
    trait :with_cover_letter do
      cover_letter { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    end
    
    trait :with_notes do
      notes { Faker::Lorem.paragraph }
    end
    
    trait :with_interviews do
      transient do
        interviews_count { 2 }
      end
      
      after(:create) do |application, evaluator|
        create_list(:interview, evaluator.interviews_count, application: application)
      end
    end
    
    trait :with_rating do
      rating { rand(1..5) }
    end
    
    trait :highly_rated do
      rating { rand(4..5) }
    end
    
    trait :poorly_rated do
      rating { rand(1..2) }
    end
    
    # Source-specific traits
    trait :from_referral do
      source { 'referral' }
      metadata { { 'referrer_id' => '12345', 'referrer_bonus_eligible' => true } }
    end
    
    trait :from_job_board do
      source { 'indeed' }
      metadata { { 'source_campaign' => 'software_engineer_q4_2023' } }
    end
    
    trait :from_career_page do
      source { 'website' }
    end
    
    trait :from_linkedin do
      source { 'linkedin' }
    end
    
    # Metadata-based traits
    trait :with_metadata do
      metadata { 
        {
          'source_details' => { 'campaign_id' => 'summer_2023' },
          'screening_notes' => 'Initial phone screen completed',
          'priority' => 'normal'
        }
      }
    end
    
    trait :urgent do
      metadata { { 'priority' => 'high', 'reason' => 'Candidate has competing offers' } }
    end
    
    trait :with_stage_changed_by do
      stage_changed_by { association :user, company: company }
      stage_changed_at { 1.day.ago }
    end
  end
end