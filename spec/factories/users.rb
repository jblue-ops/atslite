FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    role { :readonly }
    settings { { 'theme' => 'light', 'notifications' => true } }
    company
    
    # Generate email based on company's email domain
    email do
      domain = company.email_domain || 'example.com'
      "#{Faker::Internet.username}@#{domain}"
    end
    
    trait :admin do
      role { :admin }
    end
    
    trait :recruiter do
      role { :recruiter }
    end
    
    trait :interviewer do
      role { :interviewer }
    end
    
    trait :readonly do
      role { :readonly }
    end
    
    trait :active do
      last_login_at { 1.week.ago }
    end
    
    trait :inactive do
      last_login_at { 2.months.ago }
    end
    
    trait :recently_active do
      last_login_at { 2.days.ago }
    end
    
    trait :never_logged_in do
      last_login_at { nil }
    end
    
    trait :with_avatar do
      after(:build) do |user|
        user.avatar.attach(
          io: StringIO.new('fake avatar data'),
          filename: 'avatar.jpg',
          content_type: 'image/jpeg'
        )
      end
    end
    
    # Create user with specific email domain matching company
    trait :with_company_email do
      transient do
        company_domain { 'example.com' }
      end
      
      email { "#{Faker::Internet.username}@#{company_domain}" }
      company { association :company, email_domain: company_domain }
    end
    
    trait :with_settings do
      settings do
        {
          'theme' => 'dark',
          'notifications' => true,
          'language' => 'en'
        }
      end
    end
    
    # User with last login at specific time
    trait :logged_in_recently do
      last_login_at { 3.days.ago }
    end
    
    trait :logged_in_long_ago do
      last_login_at { 60.days.ago }
    end
  end
end