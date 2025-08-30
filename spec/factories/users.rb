FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.unique.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    confirmed_at { Time.current }
    company
    
    trait :admin do
      role { 'admin' }
    end
    
    trait :recruiter do
      role { 'recruiter' }
    end
    
    trait :interviewer do
      role { 'interviewer' }
      department { 'Engineering' }
    end
    
    trait :hiring_manager do
      role { 'hiring_manager' }
      department { 'Engineering' }
    end
    
    trait :unconfirmed do
      confirmed_at { nil }
      confirmation_token { SecureRandom.hex(10) }
    end
    
    trait :inactive do
      active { false }
      deactivated_at { 1.week.ago }
    end
    
    trait :with_profile_picture do
      after(:build) do |user|
        user.profile_picture.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'profile.jpg')),
          filename: 'profile.jpg',
          content_type: 'image/jpeg'
        )
      end
    end
    
    # Create user with specific email domain
    trait :with_company_email do
      transient do
        company_domain { 'example.com' }
      end
      
      email { "#{Faker::Internet.username}@#{company_domain}" }
    end
    
    # User with timezone
    trait :with_timezone do
      time_zone { 'America/New_York' }
    end
  end
end