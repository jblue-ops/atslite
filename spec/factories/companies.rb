FactoryBot.define do
  factory :company do
    name { Faker::Company.name }
    sequence(:slug) { |n| "#{Faker::Internet.slug}-#{n}" }
    email_domain { Faker::Internet.domain_name }
    subscription_plan { :free }
    settings { { 'timezone' => 'UTC', 'date_format' => 'MM/DD/YYYY' } }
    
    # Ensure slug is valid format
    after(:build) do |company|
      if company.slug.present?
        company.slug = company.slug.downcase.gsub(/[^a-z0-9\-]/, '-').gsub(/-+/, '-').gsub(/^-|-$/, '')
      end
    end
    
    trait :with_logo do
      after(:build) do |company|
        company.logo.attach(
          io: StringIO.new('fake image data'),
          filename: 'company_logo.png',
          content_type: 'image/png'
        )
      end
    end
    
    trait :with_email_domain do
      email_domain { 'example.com' }
    end
    
    trait :without_email_domain do
      email_domain { nil }
    end
    
    # Traits for different subscription levels
    trait :free_plan do
      subscription_plan { :free }
    end
    
    trait :professional_plan do
      subscription_plan { :professional }
    end
    
    trait :enterprise_plan do
      subscription_plan { :enterprise }
    end
    
    trait :with_settings do
      settings do
        {
          'max_interviews_per_day' => 5,
          'email_notifications' => true,
          'theme' => 'light'
        }
      end
    end
    
    trait :with_users do
      after(:create) do |company|
        create(:user, :admin, company: company)
        create_list(:user, 2, company: company)
      end
    end
  end
end