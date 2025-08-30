FactoryBot.define do
  factory :interview do
    application
    interviewer { association :user, company: application.company }
    interview_type { ['phone', 'technical', 'behavioral', 'onsite', 'panel'].sample }
    status { 'scheduled' }
    scheduled_at { 1.week.from_now }
    duration_minutes { 60 }
    location { 'Conference Room A' }
    video_link { nil }
    notes { 'Please review candidate resume before interview' }
    metadata { { 'interview_round' => 1, 'preparation_time' => 30 } }
    
    trait :phone do
      interview_type { 'phone' }
      duration_minutes { 30 }
      location { nil }
      video_link { nil }
    end
    
    trait :technical do
      interview_type { 'technical' }
      duration_minutes { 90 }
      metadata { { 'preparation_notes' => 'Focus on Ruby/Rails experience and problem-solving approach' } }
    end
    
    trait :behavioral do
      interview_type { 'behavioral' }
      duration_minutes { 45 }
      metadata { { 'focus_areas' => ['Leadership', 'Collaboration', 'Problem solving', 'Cultural fit'] } }
    end
    
    trait :final_interview do
      interview_type { 'final_interview' }
      interviewer { association :user, company: application.company }
      duration_minutes { 45 }
      metadata { { 'decision_maker' => true } }
    end
    
    trait :panel do
      interview_type { 'panel' }
      duration_minutes { 75 }
      metadata { { 'panel_size' => 3 } }
    end
    
    trait :video do
      interview_type { 'video' }
      location { nil }
      video_link { 'https://zoom.us/j/123456789' }
      metadata { { 'meeting_password' => 'interview123' } }
    end
    
    trait :onsite do
      interview_type { 'onsite' }
      location { 'Main Office - Conference Room B' }
      video_link { nil }
      metadata { { 'parking_instructions' => 'Visitor parking available in front of building' } }
    end
    
    trait :completed do
      status { 'completed' }
      completed_at { 1.day.ago }
      scheduled_at { 2.days.ago }
      feedback { 'Great interview, candidate showed strong technical skills' }
      rating { rand(3..5) }
      decision { ['yes', 'strong_yes', 'maybe'].sample }
    end
    
    trait :no_show do
      status { 'no_show' }
      scheduled_at { 1.day.ago }
      notes { 'Candidate did not show up for scheduled interview' }
    end
    
    trait :cancelled do
      status { 'cancelled' }
      notes { 'Interview cancelled due to scheduling conflict' }
    end
    
    trait :confirmed do
      status { 'confirmed' }
      metadata { { 'confirmed_at' => 1.hour.ago } }
    end
    
    trait :urgent do
      metadata { { 'priority' => 'high', 'reason' => 'Candidate has competing offers' } }
    end
    
    trait :with_preparation_notes do
      metadata { { 'preparation_materials' => ['Resume', 'Job Description', 'Company Overview'] } }
    end
    
    trait :with_coding_challenge do
      interview_type { 'technical' }
      metadata { 
        { 
          'coding_challenge_url' => 'https://coderpad.io/interview/abc123',
          'coding_languages' => ['Ruby', 'JavaScript', 'Python']
        } 
      }
    end
    
    trait :with_presentation do
      metadata { 
        { 
          'presentation_required' => true,
          'presentation_topic' => 'System design for scalable web application'
        } 
      }
    end
    
    trait :with_salary_discussion do
      metadata { { 'include_salary_discussion' => true } }
    end
    
    trait :with_calendar_event do
      calendar_event_id { 'cal_event_' + SecureRandom.alphanumeric(8) }
    end
    
    # Scheduling-related traits
    trait :early_morning do
      scheduled_at { 2.days.from_now.change(hour: 8, min: 0) }
    end
    
    trait :late_afternoon do
      scheduled_at { 2.days.from_now.change(hour: 17, min: 0) }
    end
    
    trait :next_week do
      scheduled_at { 1.week.from_now.change(hour: 14, min: 0) }
    end
    
    # Positive/Negative outcomes
    trait :positive_outcome do
      status { 'completed' }
      completed_at { 1.day.ago }
      scheduled_at { 2.days.ago }
      rating { rand(4..5) }
      decision { ['yes', 'strong_yes'].sample }
      feedback { 'Excellent candidate with strong skills and great cultural fit' }
    end
    
    trait :negative_outcome do
      status { 'completed' }
      completed_at { 1.day.ago }
      scheduled_at { 2.days.ago }
      rating { rand(1..2) }
      decision { ['no', 'strong_no'].sample }
      feedback { 'Candidate lacks the required skills for this position' }
    end
  end
end