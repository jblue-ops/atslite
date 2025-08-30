# frozen_string_literal: true

RSpec.describe Company, type: :model do
  # Let blocks for test setup
  let(:valid_attributes) do
    {
      name: 'Test Company',
      slug: 'test-company',
      email_domain: 'example.com',
      subscription_plan: 'free',
      settings: {}
    }
  end

  let(:company) { build(:company, **valid_attributes) }

  describe 'associations' do
    it { should have_many(:users).dependent(:destroy) }
    it { should have_many(:jobs).dependent(:destroy) }
    it { should have_many(:applications).dependent(:destroy) }
    it { should have_many(:candidates).through(:applications) }
    it { should have_many(:interviews).through(:applications) }
    it { should have_one_attached(:logo) }
  end

  describe 'validations' do
    subject { company }

    describe 'name validation' do
      it { should validate_presence_of(:name) }
      it { should validate_length_of(:name).is_at_least(2).is_at_most(100) }

      it 'accepts valid names' do
        valid_names = ['Test Co', 'A Very Long Company Name Inc.', 'Tech-Start']
        valid_names.each do |name|
          company.name = name
          expect(company).to be_valid, "#{name} should be valid"
        end
      end

      it 'rejects names that are too short' do
        company.name = 'A'
        expect(company).to be_invalid
        expect(company.errors[:name]).to include('is too short (minimum is 2 characters)')
      end

      it 'rejects names that are too long' do
        company.name = 'A' * 101
        expect(company).to be_invalid
        expect(company.errors[:name]).to include('is too long (maximum is 100 characters)')
      end
    end

    describe 'slug validation' do
      it { should validate_presence_of(:slug) }
      it { should validate_uniqueness_of(:slug) }
      it { should validate_length_of(:slug).is_at_least(2).is_at_most(50) }

      context 'format validation' do
        it 'accepts valid slugs' do
          valid_slugs = ['test-company', 'my-startup', 'company123', 'a-b-c-d-e']
          valid_slugs.each do |slug|
            company.slug = slug
            expect(company).to be_valid, "#{slug} should be valid"
          end
        end

        it 'rejects invalid slugs' do
          invalid_slugs = ['Test-Company', 'test_company', 'test company', 'test-', '-test', 'test--company', '']
          invalid_slugs.each do |slug|
            company.slug = slug
            expect(company).to be_invalid, "#{slug} should be invalid"
            expect(company.errors[:slug]).to include('must contain only lowercase letters, numbers, and hyphens')
          end
        end

        it 'rejects slugs with special characters' do
          special_chars = ['test!', 'test@company', 'test#', 'test$', 'test%']
          special_chars.each do |slug|
            company.slug = slug
            expect(company).to be_invalid
            expect(company.errors[:slug]).to include('must contain only lowercase letters, numbers, and hyphens')
          end
        end
      end

      it 'ensures uniqueness across companies' do
        existing_company = create(:company, slug: 'unique-slug')
        company.slug = 'unique-slug'
        expect(company).to be_invalid
        expect(company.errors[:slug]).to include('has already been taken')
      end
    end

    describe 'email_domain validation' do
      it 'accepts valid domains' do
        valid_domains = ['example.com', 'test-company.org', 'my.domain.co.uk', 'sub.domain.com']
        valid_domains.each do |domain|
          company.email_domain = domain
          expect(company).to be_valid, "#{domain} should be valid"
        end
      end

      it 'accepts blank email domains' do
        company.email_domain = nil
        expect(company).to be_valid
        
        company.email_domain = ''
        expect(company).to be_valid
      end

      it 'rejects invalid domain formats' do
        invalid_domains = ['invalid', 'test.', '.com', 'test..com', 'test .com', 'test@domain.com']
        invalid_domains.each do |domain|
          company.email_domain = domain
          expect(company).to be_invalid, "#{domain} should be invalid"
          expect(company.errors[:email_domain]).to include('must be a valid domain format')
        end
      end

      it 'rejects domains that are too short' do
        company.email_domain = 'a.b'
        expect(company).to be_invalid
        expect(company.errors[:email_domain]).to include('must be a valid domain format')
      end
    end

    describe 'subscription_plan validation' do
      it { should validate_presence_of(:subscription_plan) }
      it { should define_enum_for(:subscription_plan).with_values(free: 0, professional: 1, enterprise: 2).with_prefix }

      it 'defaults to free plan' do
        company = Company.new(valid_attributes.except(:subscription_plan))
        expect(company.subscription_plan).to eq('free')
      end
    end

    describe 'settings validation' do
      it { should validate_presence_of(:settings) }

      it 'defaults to empty hash' do
        company = Company.new(valid_attributes.except(:settings))
        company.valid? # trigger default value assignment
        expect(company.settings).to eq({})
      end

      it 'accepts valid JSONB data' do
        valid_settings = [
          {},
          { 'key' => 'value' },
          { 'nested' => { 'data' => true } },
          { 'array' => [1, 2, 3] }
        ]
        
        valid_settings.each do |setting|
          company.settings = setting
          expect(company).to be_valid, "#{setting} should be valid"
        end
      end
    end
  end

  describe 'logo attachment validations' do
    let(:company_with_logo) { build(:company) }

    context 'with valid logo' do
      it 'accepts valid image formats' do
        valid_types = %w[image/jpeg image/jpg image/png image/webp]
        
        valid_types.each do |content_type|
          allow(company_with_logo.logo).to receive(:attached?).and_return(true)
          allow(company_with_logo.logo).to receive(:content_type).and_return(content_type)
          allow(company_with_logo.logo).to receive_message_chain(:blob, :byte_size).and_return(1.megabyte)
          
          expect(company_with_logo).to be_valid
        end
      end

      it 'accepts logos under 5MB' do
        allow(company_with_logo.logo).to receive(:attached?).and_return(true)
        allow(company_with_logo.logo).to receive(:content_type).and_return('image/png')
        allow(company_with_logo.logo).to receive_message_chain(:blob, :byte_size).and_return(4.megabytes)
        
        expect(company_with_logo).to be_valid
      end
    end

    context 'with invalid logo' do
      it 'rejects invalid content types' do
        invalid_types = %w[image/gif text/plain application/pdf video/mp4]
        
        invalid_types.each do |content_type|
          allow(company_with_logo.logo).to receive(:attached?).and_return(true)
          allow(company_with_logo.logo).to receive(:content_type).and_return(content_type)
          allow(company_with_logo.logo).to receive_message_chain(:blob, :byte_size).and_return(1.megabyte)
          
          expect(company_with_logo).to be_invalid
          expect(company_with_logo.errors[:logo]).to include('must be a JPEG, PNG, or WebP image')
        end
      end

      it 'rejects logos over 5MB' do
        allow(company_with_logo.logo).to receive(:attached?).and_return(true)
        allow(company_with_logo.logo).to receive(:content_type).and_return('image/png')
        allow(company_with_logo.logo).to receive_message_chain(:blob, :byte_size).and_return(6.megabytes)
        
        expect(company_with_logo).to be_invalid
        expect(company_with_logo.errors[:logo]).to include('must be less than 5MB')
      end
    end
  end

  describe 'enums' do
    it { should define_enum_for(:subscription_plan).with_values(free: 0, professional: 1, enterprise: 2).with_prefix }

    describe 'subscription plan enum methods' do
      it 'provides predicate methods' do
        company = build(:company, subscription_plan: :free)
        expect(company.subscription_plan_free?).to be true
        expect(company.subscription_plan_professional?).to be false
        expect(company.subscription_plan_enterprise?).to be false

        company.subscription_plan = :professional
        expect(company.subscription_plan_free?).to be false
        expect(company.subscription_plan_professional?).to be true
        expect(company.subscription_plan_enterprise?).to be false

        company.subscription_plan = :enterprise
        expect(company.subscription_plan_free?).to be false
        expect(company.subscription_plan_professional?).to be false
        expect(company.subscription_plan_enterprise?).to be true
      end

      it 'provides scopes for subscription plans' do
        free_company = create(:company, subscription_plan: :free)
        pro_company = create(:company, subscription_plan: :professional)
        enterprise_company = create(:company, subscription_plan: :enterprise)

        expect(Company.subscription_plan_free).to include(free_company)
        expect(Company.subscription_plan_professional).to include(pro_company)
        expect(Company.subscription_plan_enterprise).to include(enterprise_company)
      end
    end
  end

  describe 'scopes' do
    let!(:free_company) { create(:company, subscription_plan: :free, created_at: 2.days.ago) }
    let!(:pro_company) { create(:company, subscription_plan: :professional, created_at: 1.day.ago, name: 'ABC Company') }
    let!(:enterprise_company) { create(:company, subscription_plan: :enterprise, created_at: Time.current, name: 'XYZ Corp') }
    let!(:company_with_domain) { create(:company, email_domain: 'test.com') }
    let!(:company_without_domain) { create(:company, email_domain: nil) }

    describe '.by_subscription_plan' do
      it 'filters by subscription plan' do
        expect(Company.by_subscription_plan(:free)).to include(free_company)
        expect(Company.by_subscription_plan(:free)).not_to include(pro_company)
        
        expect(Company.by_subscription_plan(:professional)).to include(pro_company)
        expect(Company.by_subscription_plan(:professional)).not_to include(free_company)
      end
    end

    describe '.with_email_domain' do
      it 'returns companies with email domains' do
        results = Company.with_email_domain
        expect(results).to include(company_with_domain)
        expect(results).not_to include(company_without_domain)
      end
    end

    describe '.recent' do
      it 'orders by created_at desc' do
        results = Company.recent
        expect(results.first).to eq(enterprise_company)
        expect(results.last).to eq(free_company)
      end
    end

    describe '.alphabetical' do
      it 'orders by name' do
        results = Company.alphabetical
        expect(results.first.name).to start_with('ABC')
        expect(results.last.name).to start_with('XYZ')
      end
    end

    describe '.active' do
      let!(:company_with_users) { create(:company) }
      let!(:company_without_users) { create(:company) }

      before do
        create(:user, company: company_with_users)
      end

      it 'returns companies with users' do
        results = Company.active
        expect(results).to include(company_with_users)
        expect(results).not_to include(company_without_users)
      end
    end
  end

  describe 'callbacks' do
    describe '#normalize_slug' do
      it 'normalizes slug before validation' do
        test_cases = {
          'Test Company!' => 'test-company',
          'TEST_COMPANY' => 'test-company',
          'test---company' => 'test-company',
          '-test-company-' => 'test-company',
          'Test   Company' => 'test-company'
        }

        test_cases.each do |input, expected|
          company.slug = input
          company.valid? # trigger normalization
          expect(company.slug).to eq(expected), "Expected '#{input}' to normalize to '#{expected}', got '#{company.slug}'"
        end
      end

      it 'handles edge cases' do
        company.slug = '   '
        company.valid?
        expect(company.slug).to eq('')

        company.slug = '!@#$%'
        company.valid?
        expect(company.slug).to eq('')
      end
    end

    describe '#normalize_email_domain' do
      it 'normalizes email domain before validation' do
        test_cases = {
          'EXAMPLE.COM' => 'example.com',
          '  test.com  ' => 'test.com',
          'Test-Domain.ORG' => 'test-domain.org'
        }

        test_cases.each do |input, expected|
          company.email_domain = input
          company.valid?
          expect(company.email_domain).to eq(expected)
        end
      end
    end
  end

  describe 'class methods' do
    describe '.find_by_domain' do
      let!(:company_with_domain) { create(:company, email_domain: 'example.com') }

      it 'finds company by email domain' do
        result = Company.find_by_domain('example.com')
        expect(result).to eq(company_with_domain)
      end

      it 'returns nil for non-existent domain' do
        result = Company.find_by_domain('nonexistent.com')
        expect(result).to be_nil
      end
    end

    describe '.search' do
      let!(:tech_company) { create(:company, name: 'Tech Innovations', slug: 'tech-innovations') }
      let!(:consulting_company) { create(:company, name: 'Business Consulting', slug: 'biz-consulting') }

      it 'searches by name' do
        results = Company.search('Tech')
        expect(results).to include(tech_company)
        expect(results).not_to include(consulting_company)
      end

      it 'searches by slug' do
        results = Company.search('biz')
        expect(results).to include(consulting_company)
        expect(results).not_to include(tech_company)
      end

      it 'is case insensitive' do
        results = Company.search('TECH')
        expect(results).to include(tech_company)
      end

      it 'returns empty result for no matches' do
        results = Company.search('NonExistent')
        expect(results).to be_empty
      end
    end
  end

  describe 'instance methods' do
    let(:company) { create(:company, name: 'Test Company', slug: 'test-company') }

    describe '#display_name' do
      it 'returns the company name' do
        expect(company.display_name).to eq('Test Company')
      end
    end

    describe '#to_param' do
      it 'returns the slug for URL generation' do
        expect(company.to_param).to eq('test-company')
      end
    end

    describe '#user_count' do
      it 'returns the number of users' do
        expect(company.user_count).to eq(0)
        
        create_list(:user, 3, company: company)
        expect(company.user_count).to eq(3)
      end
    end

    describe '#active_users' do
      let!(:active_user) { create(:user, company: company, last_login_at: 1.week.ago) }
      let!(:inactive_user) { create(:user, company: company, last_login_at: 2.months.ago) }
      let!(:never_logged_user) { create(:user, company: company, last_login_at: nil) }

      it 'returns users who logged in within 30 days' do
        active_users = company.active_users
        expect(active_users).to include(active_user)
        expect(active_users).not_to include(inactive_user, never_logged_user)
      end
    end

    describe '#admin_users' do
      let!(:admin_user) { create(:user, company: company, role: :admin) }
      let!(:regular_user) { create(:user, company: company, role: :readonly) }

      it 'returns only admin users' do
        admin_users = company.admin_users
        expect(admin_users).to include(admin_user)
        expect(admin_users).not_to include(regular_user)
      end
    end

    describe '#can_add_users?' do
      context 'with free subscription' do
        let(:free_company) { create(:company, subscription_plan: :free) }

        it 'allows adding users when under limit' do
          create_list(:user, 4, company: free_company)
          expect(free_company.can_add_users?).to be true
        end

        it 'prevents adding users when at limit' do
          create_list(:user, 5, company: free_company)
          expect(free_company.can_add_users?).to be false
        end

        it 'prevents adding users when over limit' do
          create_list(:user, 6, company: free_company)
          expect(free_company.can_add_users?).to be false
        end
      end

      context 'with professional subscription' do
        let(:pro_company) { create(:company, subscription_plan: :professional) }

        it 'allows adding users when under limit' do
          create_list(:user, 49, company: pro_company)
          expect(pro_company.can_add_users?).to be true
        end

        it 'prevents adding users when at limit' do
          create_list(:user, 50, company: pro_company)
          expect(pro_company.can_add_users?).to be false
        end
      end

      context 'with enterprise subscription' do
        let(:enterprise_company) { create(:company, subscription_plan: :enterprise) }

        it 'always allows adding users' do
          create_list(:user, 1000, company: enterprise_company)
          expect(enterprise_company.can_add_users?).to be true
        end
      end
    end

    describe '#setting and #update_setting' do
      it 'gets and sets individual settings' do
        company.update_setting(:max_interviews_per_day, 5)
        expect(company.setting(:max_interviews_per_day)).to eq(5)
        expect(company.setting('max_interviews_per_day')).to eq(5)
      end

      it 'returns nil for non-existent settings' do
        expect(company.setting(:non_existent)).to be_nil
      end

      it 'handles nested settings' do
        company.update_setting(:email_settings, { enabled: true, template: 'default' })
        expect(company.setting(:email_settings)).to eq({ 'enabled' => true, 'template' => 'default' })
      end

      it 'persists settings to database' do
        company.update_setting(:theme, 'dark')
        company.reload
        expect(company.setting(:theme)).to eq('dark')
      end
    end

    describe '#logo_url' do
      context 'with logo attached' do
        it 'returns the logo URL' do
          allow(company.logo).to receive(:attached?).and_return(true)
          allow(Rails.application.routes.url_helpers).to receive(:rails_blob_url).and_return('/logo.png')
          
          expect(company.logo_url).to eq('/logo.png')
        end
      end

      context 'without logo attached' do
        it 'returns nil' do
          allow(company.logo).to receive(:attached?).and_return(false)
          expect(company.logo_url).to be_nil
        end
      end
    end
  end

  describe 'edge cases' do
    describe 'slug generation with special characters' do
      it 'handles unicode characters' do
        company.slug = 'café-münchën'
        company.valid?
        expect(company.slug).to eq('caf-m-nch-n')
      end

      it 'handles numbers and letters mixed' do
        company.slug = 'company123test'
        company.valid?
        expect(company.slug).to eq('company123test')
      end
    end

    describe 'JSONB settings handling' do
      it 'preserves data types in settings' do
        settings_data = {
          string: 'value',
          number: 42,
          boolean: true,
          array: [1, 2, 3],
          hash: { nested: 'data' },
          null_value: nil
        }
        
        company.settings = settings_data
        company.save!
        company.reload
        
        expect(company.settings['string']).to eq('value')
        expect(company.settings['number']).to eq(42)
        expect(company.settings['boolean']).to be true
        expect(company.settings['array']).to eq([1, 2, 3])
        expect(company.settings['hash']).to eq({ 'nested' => 'data' })
        expect(company.settings['null_value']).to be_nil
      end
    end

    describe 'email domain validation edge cases' do
      it 'handles internationalized domains' do
        # This might need adjustment based on actual requirements
        company.email_domain = 'münchen.de'
        expect(company).to be_invalid # Assuming ASCII-only validation
      end

      it 'handles very long valid domains' do
        long_domain = "#{'a' * 60}.com"
        company.email_domain = long_domain
        expect(company).to be_invalid # Too long subdomain
      end
    end
  end
end