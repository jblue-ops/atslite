# frozen_string_literal: true

FactoryBot.define do
  factory :interview do
    application
    interviewer { association :user, :interviewer, company: application.job.company }
    interview_type { %w[phone_screen technical behavioral final panel].sample }
    status { "scheduled" }
    scheduled_at { 1.week.from_now }
    duration_minutes { 60 }
    location { "Conference Room A" }
    meeting_link { "https://meet.google.com/abc-defg-hij" }
    notes { "Please review candidate resume before interview" }

    trait :phone_screen do
      interview_type { "phone_screen" }
      duration_minutes { 30 }
      location { nil }
      meeting_link { nil }
      phone_number { Faker::PhoneNumber.phone_number }
    end

    trait :technical_interview do
      interview_type { "technical" }
      duration_minutes { 90 }
      preparation_notes { "Focus on Ruby/Rails experience and problem-solving approach" }
      technical_requirements { ["Laptop with code editor", "Screen sharing capability"] }
    end

    trait :behavioral_interview do
      interview_type { "behavioral" }
      duration_minutes { 45 }
      focus_areas { ["Leadership", "Collaboration", "Problem solving", "Cultural fit"] }
    end

    trait :final_interview do
      interview_type { "final" }
      interviewer { association :user, :hiring_manager, company: application.job.company }
      duration_minutes { 45 }
      decision_maker { true }
    end

    trait :panel_interview do
      interview_type { "panel" }
      duration_minutes { 75 }
      after(:create) do |interview|
        create_list(:interview_participant, 3, interview: interview)
      end
    end

    trait :virtual do
      location { "Virtual" }
      meeting_link { "https://zoom.us/j/123456789" }
      meeting_password { "interview123" }
      tech_check_required { true }
    end

    trait :in_person do
      location { "Main Office - Conference Room B" }
      meeting_link { nil }
      parking_instructions { "Visitor parking available in front of building" }
      office_contact { "Reception: (555) 123-4567" }
    end

    trait :completed do
      status { "completed" }
      completed_at { 1.day.ago }
      scheduled_at { 2.days.ago }
      actual_duration_minutes { duration_minutes + rand(-10..15) }
      after(:create) do |interview|
        create(:interview_feedback, interview: interview)
      end
    end

    trait :no_show do
      status { "no_show" }
      scheduled_at { 1.day.ago }
      no_show_reason { "candidate_no_show" }
    end

    trait :cancelled do
      status { "cancelled" }
      cancelled_at { 2.hours.ago }
      cancellation_reason { "scheduling_conflict" }
      cancelled_by { "interviewer" }
    end

    trait :rescheduled do
      status { "rescheduled" }
      original_scheduled_at { 2.days.ago }
      rescheduled_at { 4.hours.ago }
      reschedule_reason { "interviewer_conflict" }
    end

    trait :urgent do
      priority { "high" }
      urgent_reason { "Candidate has competing offers" }
    end

    trait :with_preparation_materials do
      after(:create) do |interview|
        create_list(:interview_material, 2, interview: interview)
      end
    end

    trait :with_coding_challenge do
      technical_interview
      coding_challenge_url { "https://coderpad.io/interview/abc123" }
      coding_languages { %w[Ruby JavaScript Python] }
      challenge_description { "Implement a solution for the given algorithm problem" }
    end

    trait :with_presentation do
      presentation_required { true }
      presentation_topic { "System design for scalable web application" }
      presentation_duration { 15 }
    end

    trait :salary_discussion do
      include_salary_discussion { true }
      salary_range_min { application.job.salary_min }
      salary_range_max { application.job.salary_max }
    end

    trait :reference_check do
      interview_type { "reference_check" }
      duration_minutes { 20 }
      reference_contact { association :reference, candidate: application.candidate }
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

    # Interviewer-specific traits
    trait :with_senior_engineer do
      interviewer { association :user, :interviewer, role: "senior_engineer" }
      technical_interview
    end

    trait :with_hiring_manager do
      interviewer { association :user, :hiring_manager }
      final_interview
    end

    # Follow-up actions
    trait :requires_follow_up do
      follow_up_required { true }
      follow_up_deadline { 2.days.from_now }
      follow_up_actions { ["Send technical assessment", "Schedule final round"] }
    end
  end

  factory :interview_participant do
    interview
    user { association :user, :interviewer }
    role { "interviewer" }

    trait :lead_interviewer do
      role { "lead" }
    end

    trait :observer do
      role { "observer" }
    end

    trait :note_taker do
      role { "note_taker" }
    end
  end

  factory :interview_feedback do
    interview
    overall_rating { rand(1..5) }
    technical_skills { rand(1..5) }
    communication { rand(1..5) }
    problem_solving { rand(1..5) }
    cultural_fit { rand(1..5) }
    comments { Faker::Lorem.paragraphs(number: 2).join("\n\n") }
    recommendation { %w[strong_hire hire no_hire strong_no_hire].sample }

    trait :positive_feedback do
      overall_rating { rand(4..5) }
      technical_skills { rand(4..5) }
      communication { rand(4..5) }
      problem_solving { rand(4..5) }
      cultural_fit { rand(4..5) }
      recommendation { %w[strong_hire hire].sample }
      comments do
        "Excellent candidate with strong technical skills. " \
          "Demonstrated clear thinking and good communication throughout the interview. " \
          "Would be a great addition to the team."
      end
    end

    trait :negative_feedback do
      overall_rating { rand(1..2) }
      technical_skills { rand(1..2) }
      recommendation { %w[no_hire strong_no_hire].sample }
      comments do
        "Candidate struggled with basic technical concepts. " \
          "Unable to solve the coding challenge effectively. " \
          "Would need significant mentoring to be productive."
      end
    end

    trait :mixed_feedback do
      overall_rating { 3 }
      technical_skills { rand(2..4) }
      communication { rand(3..4) }
      recommendation { "no_hire" }
      comments do
        "Candidate has good communication skills and seems motivated. " \
          "However, technical skills are not quite at the level we need for this role. " \
          "Might be better suited for a more junior position."
      end
    end

    trait :with_detailed_notes do
      technical_notes { "Solved coding challenge in 25 minutes. Clean, well-structured code." }
      behavioral_notes { "Good examples of leadership and collaboration from previous roles." }
      concerns { "Limited experience with our specific tech stack (Rails)." }
      strengths { "Strong problem-solving approach, excellent communication, team player." }
    end

    trait :requires_second_opinion do
      second_interview_recommended { true }
      second_interview_reason { "Mixed signals - need technical deep dive" }
    end
  end

  factory :interview_material do
    interview
    title { "Job Description" }
    content { "Please review the attached job description before the interview." }
    material_type { "document" }

    trait :resume do
      title { "Candidate Resume" }
      material_type { "resume" }
      after(:build) do |material|
        material.file.attach(
          io: Rails.root.join("spec", "fixtures", "files", "sample_resume.pdf").open,
          filename: "candidate_resume.pdf",
          content_type: "application/pdf"
        )
      end
    end

    trait :coding_challenge do
      title { "Technical Assessment Results" }
      material_type { "assessment" }
      content { "Candidate completed coding challenge with 85% score." }
    end

    trait :portfolio do
      title { "Portfolio Review" }
      material_type { "portfolio" }
      content { "Review candidate portfolio at: https://portfolio.example.com" }
    end
  end

  factory :interview_availability do
    user
    start_time { Time.current.next_week.beginning_of_week + 9.hours }
    end_time { start_time + 8.hours }
    day_of_week { start_time.wday }

    trait :morning_only do
      start_time { Time.current.next_week.beginning_of_week + 9.hours }
      end_time { start_time + 4.hours }
    end

    trait :afternoon_only do
      start_time { Time.current.next_week.beginning_of_week + 13.hours }
      end_time { start_time + 5.hours }
    end

    trait :all_day do
      start_time { Time.current.next_week.beginning_of_week + 8.hours }
      end_time { start_time + 10.hours }
    end
  end
end
