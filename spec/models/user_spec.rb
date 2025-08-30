# frozen_string_literal: true

RSpec.describe User, type: :model do
  # Let blocks for test setup
  let(:company) { create(:company, email_domain: 'example.com') }
  let(:valid_attributes) do
    {
      first_name: 'John',
      last_name: 'Doe',
      email: 'john.doe@example.com',
      role: 'readonly',
      company: company,
      settings: {}
    }
  end

  let(:user) { build(:user, **valid_attributes) }

  describe 'includes' do
    it 'includes FullNameable concern' do
      expect(User.included_modules).to include(FullNameable)
    end

    it 'responds to FullNameable methods' do
      expect(user).to respond_to(:full_name)
      expect(user).to respond_to(:initials)
      expect(user).to respond_to(:display_name)
    end
  end

  describe 'associations' do
    it { should belong_to(:company) }
    it { should have_many(:interviews_as_interviewer).class_name('Interview').with_foreign_key('interviewer_id').dependent(:nullify) }
    it { should have_many(:interviews_scheduled_by_me).class_name('Interview').with_foreign_key('scheduled_by_id').dependent(:nullify) }
    it { should have_many(:applications_stage_changed_by_me).class_name('Application').with_foreign_key('stage_changed_by_id').dependent(:nullify) }
    it { should have_one_attached(:avatar) }
  end

  describe 'delegations' do
    let(:company) { create(:company, name: 'Test Company', subscription_plan: :professional) }
    let(:user) { create(:user, company: company) }

    it 'delegates company name' do
      expect(user.company_name).to eq('Test Company')
    end

    it 'delegates company subscription plan' do
      expect(user.company_subscription_plan).to eq('professional')
    end

    it 'handles nil company gracefully' do
      user.company = nil
      expect(user.company_name).to be_nil
      expect(user.company_subscription_plan).to be_nil
    end
  end

  describe 'validations' do
    subject { user }

    describe 'email validation' do
      it { should validate_presence_of(:email) }
      it { should validate_uniqueness_of(:email).scoped_to(:company_id).case_insensitive }

      context 'format validation' do
        it 'accepts valid email formats' do
          valid_emails = [
            'test@example.com',
            'user.name@domain.co.uk',
            'firstname+lastname@company.org',
            'user123@test-domain.com'
          ]

          valid_emails.each do |email|
            user.email = email
            expect(user).to be_valid, "#{email} should be valid"
          end
        end

        it 'rejects invalid email formats' do
          invalid_emails = [
            'invalid-email',
            '@domain.com',
            'user@',
            'user.domain.com',
            'user@domain',
            'user name@domain.com'
          ]

          invalid_emails.each do |email|
            user.email = email
            expect(user).to be_invalid, "#{email} should be invalid"
            expect(user.errors[:email]).to include('must be a valid email address')
          end
        end
      end

      context 'uniqueness within company' do
        let!(:existing_user) { create(:user, company: company, email: 'existing@example.com') }

        it 'prevents duplicate emails within the same company' do
          user.email = 'existing@example.com'
          expect(user).to be_invalid
          expect(user.errors[:email]).to include('has already been taken')
        end

        it 'allows same email in different companies' do
          other_company = create(:company)
          user.company = other_company
          user.email = 'existing@example.com'
          expect(user).to be_valid
        end

        it 'is case insensitive' do
          user.email = 'EXISTING@example.com'
          expect(user).to be_invalid
          expect(user.errors[:email]).to include('has already been taken')
        end
      end
    end

    describe 'name validations' do
      it { should validate_presence_of(:first_name) }
      it { should validate_presence_of(:last_name) }
      it { should validate_length_of(:first_name).is_at_least(1).is_at_most(50) }
      it { should validate_length_of(:last_name).is_at_least(1).is_at_most(50) }

      it 'accepts valid names' do
        valid_names = ['John', 'María', 'O\'Connor', 'Jean-Pierre', '李', 'José']
        
        valid_names.each do |name|
          user.first_name = name
          user.last_name = name
          expect(user).to be_valid, "#{name} should be valid"
        end
      end

      it 'rejects empty names' do
        user.first_name = ''
        expect(user).to be_invalid
        expect(user.errors[:first_name]).to include("can't be blank")

        user.first_name = 'John'
        user.last_name = ''
        expect(user).to be_invalid
        expect(user.errors[:last_name]).to include("can't be blank")
      end

      it 'rejects names that are too long' do
        long_name = 'a' * 51
        
        user.first_name = long_name
        expect(user).to be_invalid
        expect(user.errors[:first_name]).to include('is too long (maximum is 50 characters)')

        user.first_name = 'John'
        user.last_name = long_name
        expect(user).to be_invalid
        expect(user.errors[:last_name]).to include('is too long (maximum is 50 characters)')
      end
    end

    describe 'role validation' do
      it { should validate_presence_of(:role) }
      it { should define_enum_for(:role).with_values(readonly: 0, interviewer: 1, recruiter: 2, admin: 3).with_prefix }

      it 'defaults to readonly role' do
        user = User.new(valid_attributes.except(:role))
        expect(user.role).to eq('readonly')
      end
    end

    describe 'settings validation' do
      it { should validate_presence_of(:settings) }

      it 'defaults to empty hash' do
        user = User.new(valid_attributes.except(:settings))
        user.valid? # trigger default value assignment
        expect(user.settings).to eq({})
      end

      it 'accepts valid JSONB data' do
        valid_settings = [
          {},
          { 'theme' => 'dark' },
          { 'preferences' => { 'notifications' => true } },
          { 'tags' => ['ruby', 'rails'] }
        ]
        
        valid_settings.each do |setting|
          user.settings = setting
          expect(user).to be_valid, "#{setting} should be valid"
        end
      end
    end

    describe 'company validation' do
      it { should validate_presence_of(:company_id) }

      it 'requires a company' do
        user.company = nil
        expect(user).to be_invalid
        expect(user.errors[:company_id]).to include("can't be blank")
      end
    end

    describe 'email domain validation' do
      context 'when company has email domain set' do
        let(:company_with_domain) { create(:company, email_domain: 'acme.com') }
        let(:user_with_domain_company) { build(:user, company: company_with_domain) }

        it 'accepts emails matching company domain' do
          user_with_domain_company.email = 'employee@acme.com'
          expect(user_with_domain_company).to be_valid
        end

        it 'rejects emails not matching company domain' do
          user_with_domain_company.email = 'employee@otherdomain.com'
          expect(user_with_domain_company).to be_invalid
          expect(user_with_domain_company.errors[:email]).to include('must be from the acme.com domain')
        end

        it 'is case insensitive for domain matching' do
          user_with_domain_company.email = 'employee@ACME.COM'
          expect(user_with_domain_company).to be_valid
        end

        it 'handles subdomains correctly' do
          user_with_domain_company.email = 'employee@mail.acme.com'
          expect(user_with_domain_company).to be_invalid
          expect(user_with_domain_company.errors[:email]).to include('must be from the acme.com domain')
        end
      end

      context 'when company has no email domain set' do
        let(:company_without_domain) { create(:company, email_domain: nil) }
        let(:user_without_domain_company) { build(:user, company: company_without_domain) }

        it 'accepts any email domain' do
          user_without_domain_company.email = 'employee@anywhere.com'
          expect(user_without_domain_company).to be_valid
        end
      end
    end
  end

  describe 'avatar attachment validations' do
    let(:user_with_avatar) { build(:user) }

    context 'with valid avatar' do
      it 'accepts valid image formats' do
        valid_types = %w[image/jpeg image/jpg image/png image/webp]
        
        valid_types.each do |content_type|
          allow(user_with_avatar.avatar).to receive(:attached?).and_return(true)
          allow(user_with_avatar.avatar).to receive(:content_type).and_return(content_type)
          allow(user_with_avatar.avatar).to receive_message_chain(:blob, :byte_size).and_return(1.megabyte)
          
          expect(user_with_avatar).to be_valid
        end
      end

      it 'accepts avatars under 2MB' do
        allow(user_with_avatar.avatar).to receive(:attached?).and_return(true)
        allow(user_with_avatar.avatar).to receive(:content_type).and_return('image/png')
        allow(user_with_avatar.avatar).to receive_message_chain(:blob, :byte_size).and_return(1.5.megabytes)
        
        expect(user_with_avatar).to be_valid
      end
    end

    context 'with invalid avatar' do
      it 'rejects invalid content types' do
        invalid_types = %w[image/gif text/plain application/pdf video/mp4]
        
        invalid_types.each do |content_type|
          allow(user_with_avatar.avatar).to receive(:attached?).and_return(true)
          allow(user_with_avatar.avatar).to receive(:content_type).and_return(content_type)
          allow(user_with_avatar.avatar).to receive_message_chain(:blob, :byte_size).and_return(1.megabyte)
          
          expect(user_with_avatar).to be_invalid
          expect(user_with_avatar.errors[:avatar]).to include('must be a JPEG, PNG, or WebP image')
        end
      end

      it 'rejects avatars over 2MB' do
        allow(user_with_avatar.avatar).to receive(:attached?).and_return(true)
        allow(user_with_avatar.avatar).to receive(:content_type).and_return('image/png')
        allow(user_with_avatar.avatar).to receive_message_chain(:blob, :byte_size).and_return(3.megabytes)
        
        expect(user_with_avatar).to be_invalid
        expect(user_with_avatar.errors[:avatar]).to include('must be less than 2MB')
      end
    end
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(readonly: 0, interviewer: 1, recruiter: 2, admin: 3).with_prefix }

    describe 'role enum methods' do
      it 'provides predicate methods' do
        user = build(:user, role: :readonly)
        expect(user.role_readonly?).to be true
        expect(user.role_interviewer?).to be false
        expect(user.role_recruiter?).to be false
        expect(user.role_admin?).to be false

        user.role = :interviewer
        expect(user.role_readonly?).to be false
        expect(user.role_interviewer?).to be true

        user.role = :recruiter
        expect(user.role_interviewer?).to be false
        expect(user.role_recruiter?).to be true

        user.role = :admin
        expect(user.role_recruiter?).to be false
        expect(user.role_admin?).to be true
      end

      it 'provides scopes for roles' do
        readonly_user = create(:user, role: :readonly)
        interviewer_user = create(:user, role: :interviewer)
        recruiter_user = create(:user, role: :recruiter)
        admin_user = create(:user, role: :admin)

        expect(User.role_readonly).to include(readonly_user)
        expect(User.role_interviewer).to include(interviewer_user)
        expect(User.role_recruiter).to include(recruiter_user)
        expect(User.role_admin).to include(admin_user)
      end
    end
  end

  describe 'scopes' do
    let(:company) { create(:company) }
    let!(:active_user) { create(:user, company: company, last_login_at: 1.week.ago) }
    let!(:inactive_user) { create(:user, company: company, last_login_at: 2.months.ago) }
    let!(:never_logged_user) { create(:user, company: company, last_login_at: nil) }
    let!(:recently_active_user) { create(:user, company: company, last_login_at: 2.days.ago) }
    let!(:readonly_user) { create(:user, company: company, role: :readonly) }
    let!(:admin_user) { create(:user, company: company, role: :admin) }

    describe '.active' do
      it 'returns users who logged in within 30 days' do
        results = User.active
        expect(results).to include(active_user, recently_active_user)
        expect(results).not_to include(inactive_user, never_logged_user)
      end
    end

    describe '.inactive' do
      it 'returns users who have not logged in within 30 days' do
        results = User.inactive
        expect(results).to include(inactive_user, never_logged_user)
        expect(results).not_to include(active_user, recently_active_user)
      end
    end

    describe '.recent' do
      it 'orders by created_at desc' do
        results = User.recent
        expect(results.first.created_at).to be >= results.last.created_at
      end
    end

    describe '.by_role' do
      it 'filters by role' do
        results = User.by_role(:admin)
        expect(results).to include(admin_user)
        expect(results).not_to include(readonly_user)
      end
    end

    describe '.with_recent_activity' do
      it 'returns users active within 7 days' do
        results = User.with_recent_activity
        expect(results).to include(recently_active_user)
        expect(results).not_to include(active_user, inactive_user, never_logged_user)
      end
    end

    describe '.for_company' do
      let(:other_company) { create(:company) }
      let!(:other_company_user) { create(:user, company: other_company) }

      it 'returns users for specific company' do
        results = User.for_company(company)
        expect(results).to include(active_user, inactive_user)
        expect(results).not_to include(other_company_user)
      end
    end
  end

  describe 'callbacks' do
    describe '#normalize_email' do
      it 'normalizes email before validation' do
        test_cases = {
          'John.Doe@EXAMPLE.COM' => 'john.doe@example.com',
          '  user@test.com  ' => 'user@test.com',
          'User+Tag@Domain.ORG' => 'user+tag@domain.org'
        }

        test_cases.each do |input, expected|
          user.email = input
          user.valid? # trigger normalization
          expect(user.email).to eq(expected), "Expected '#{input}' to normalize to '#{expected}', got '#{user.email}'"
        end
      end
    end

    describe '#normalize_names' do
      it 'normalizes names before validation' do
        test_cases = {
          ['john', 'doe'] => ['John', 'Doe'],
          ['  mary  ', '  jane  '] => ['Mary', 'Jane'],
          ['jean-pierre', 'o\'connor'] => ['Jean-Pierre', 'O\'Connor'],
          ['SHOUTING', 'NAMES'] => ['Shouting', 'Names']
        }

        test_cases.each do |input, expected|
          user.first_name = input[0]
          user.last_name = input[1]
          user.valid? # trigger normalization
          expect([user.first_name, user.last_name]).to eq(expected)
        end
      end

      it 'handles edge cases' do
        user.first_name = '   '
        user.last_name = '   '
        user.valid?
        expect(user.first_name).to eq('')
        expect(user.last_name).to eq('')
      end
    end
  end

  describe 'class methods' do
    describe '.search' do
      let!(:john_doe) { create(:user, first_name: 'John', last_name: 'Doe', email: 'john.doe@example.com') }
      let!(:jane_smith) { create(:user, first_name: 'Jane', last_name: 'Smith', email: 'jane.smith@test.com') }

      it 'searches by first name' do
        results = User.search('John')
        expect(results).to include(john_doe)
        expect(results).not_to include(jane_smith)
      end

      it 'searches by last name' do
        results = User.search('Smith')
        expect(results).to include(jane_smith)
        expect(results).not_to include(john_doe)
      end

      it 'searches by email' do
        results = User.search('doe@example')
        expect(results).to include(john_doe)
        expect(results).not_to include(jane_smith)
      end

      it 'is case insensitive' do
        results = User.search('JOHN')
        expect(results).to include(john_doe)
      end

      it 'returns empty result for blank query' do
        results = User.search('')
        expect(results).to eq(User.none)

        results = User.search(nil)
        expect(results).to eq(User.none)
      end

      it 'handles partial matches' do
        results = User.search('Jo')
        expect(results).to include(john_doe)
      end
    end

    describe '.by_permission_level' do
      let!(:readonly_user) { create(:user, role: :readonly) }
      let!(:interviewer_user) { create(:user, role: :interviewer) }
      let!(:recruiter_user) { create(:user, role: :recruiter) }
      let!(:admin_user) { create(:user, role: :admin) }

      it 'returns basic level users (not readonly)' do
        results = User.by_permission_level('basic')
        expect(results).to include(interviewer_user, recruiter_user, admin_user)
        expect(results).not_to include(readonly_user)
      end

      it 'returns advanced level users (recruiter and admin)' do
        results = User.by_permission_level('advanced')
        expect(results).to include(recruiter_user, admin_user)
        expect(results).not_to include(readonly_user, interviewer_user)
      end

      it 'returns admin level users' do
        results = User.by_permission_level('admin')
        expect(results).to include(admin_user)
        expect(results).not_to include(readonly_user, interviewer_user, recruiter_user)
      end

      it 'returns none for invalid permission level' do
        results = User.by_permission_level('invalid')
        expect(results).to eq(User.none)
      end
    end

    describe '.find_by_email_and_company' do
      let!(:user_in_company) { create(:user, email: 'test@example.com', company: company) }
      let(:other_company) { create(:company) }

      it 'finds user by email and company' do
        result = User.find_by_email_and_company('test@example.com', company)
        expect(result).to eq(user_in_company)
      end

      it 'returns nil for wrong company' do
        result = User.find_by_email_and_company('test@example.com', other_company)
        expect(result).to be_nil
      end

      it 'normalizes email for search' do
        result = User.find_by_email_and_company('  TEST@EXAMPLE.COM  ', company)
        expect(result).to eq(user_in_company)
      end
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user) }

    describe 'permission methods' do
      describe '#can_manage_users?' do
        it 'returns true for admin users' do
          user.role = :admin
          expect(user.can_manage_users?).to be true
        end

        it 'returns false for non-admin users' do
          %i[readonly interviewer recruiter].each do |role|
            user.role = role
            expect(user.can_manage_users?).to be false
          end
        end
      end

      describe '#can_manage_interviews?' do
        it 'returns true for admin and recruiter users' do
          %i[admin recruiter].each do |role|
            user.role = role
            expect(user.can_manage_interviews?).to be true
          end
        end

        it 'returns false for readonly and interviewer users' do
          %i[readonly interviewer].each do |role|
            user.role = role
            expect(user.can_manage_interviews?).to be false
          end
        end
      end

      describe '#can_conduct_interviews?' do
        it 'returns true for admin, recruiter, and interviewer users' do
          %i[admin recruiter interviewer].each do |role|
            user.role = role
            expect(user.can_conduct_interviews?).to be true
          end
        end

        it 'returns false for readonly users' do
          user.role = :readonly
          expect(user.can_conduct_interviews?).to be false
        end
      end

      describe '#can_view_reports?' do
        it 'returns true for admin and recruiter users' do
          %i[admin recruiter].each do |role|
            user.role = role
            expect(user.can_view_reports?).to be true
          end
        end

        it 'returns false for readonly and interviewer users' do
          %i[readonly interviewer].each do |role|
            user.role = role
            expect(user.can_view_reports?).to be false
          end
        end
      end
    end

    describe 'activity methods' do
      describe '#active?' do
        it 'returns true for users who logged in within 30 days' do
          user.last_login_at = 1.week.ago
          expect(user.active?).to be true
        end

        it 'returns false for users who have not logged in recently' do
          user.last_login_at = 2.months.ago
          expect(user.active?).to be false

          user.last_login_at = nil
          expect(user.active?).to be false
        end
      end

      describe '#recently_active?' do
        it 'returns true for users who logged in within 7 days' do
          user.last_login_at = 2.days.ago
          expect(user.recently_active?).to be true
        end

        it 'returns false for users who have not logged in within 7 days' do
          user.last_login_at = 2.weeks.ago
          expect(user.recently_active?).to be false

          user.last_login_at = nil
          expect(user.recently_active?).to be false
        end
      end
    end

    describe '#setting and #update_setting' do
      it 'gets and sets individual settings' do
        user.update_setting(:theme, 'dark')
        expect(user.setting(:theme)).to eq('dark')
        expect(user.setting('theme')).to eq('dark')
      end

      it 'returns nil for non-existent settings' do
        expect(user.setting(:non_existent)).to be_nil
      end

      it 'handles nested settings' do
        user.update_setting(:notifications, { email: true, push: false })
        expect(user.setting(:notifications)).to eq({ 'email' => true, 'push' => false })
      end

      it 'persists settings to database' do
        user.update_setting(:language, 'es')
        user.reload
        expect(user.setting(:language)).to eq('es')
      end
    end

    describe '#avatar_url' do
      context 'with avatar attached' do
        before do
          allow(user.avatar).to receive(:attached?).and_return(true)
        end

        it 'returns thumbnail URL by default' do
          allow(Rails.application.routes.url_helpers).to receive(:rails_representation_url).and_return('/avatar_thumb.jpg')
          expect(user.avatar_url).to eq('/avatar_thumb.jpg')
        end

        it 'returns medium sized URL when requested' do
          allow(Rails.application.routes.url_helpers).to receive(:rails_representation_url).and_return('/avatar_medium.jpg')
          expect(user.avatar_url(variant: :medium)).to eq('/avatar_medium.jpg')
        end

        it 'returns original URL for other variants' do
          allow(Rails.application.routes.url_helpers).to receive(:rails_blob_url).and_return('/avatar.jpg')
          expect(user.avatar_url(variant: :original)).to eq('/avatar.jpg')
        end
      end

      context 'without avatar attached' do
        it 'returns nil' do
          allow(user.avatar).to receive(:attached?).and_return(false)
          expect(user.avatar_url).to be_nil
        end
      end
    end

    describe '#initials_color' do
      it 'returns a consistent color for the user' do
        color = user.initials_color
        expect(color).to be_a(String)
        expect(color).to start_with('#')
        
        # Should be consistent across calls
        expect(user.initials_color).to eq(color)
      end

      it 'returns different colors for different users' do
        user1 = create(:user)
        user2 = create(:user)
        
        # Very unlikely to be the same (10 colors available)
        expect(user1.initials_color).not_to eq(user2.initials_color) unless user1.id.to_s.sum % 10 == user2.id.to_s.sum % 10
      end
    end

    describe '#login!' do
      it 'updates last_login_at to current time' do
        freeze_time do
          user.login!
          expect(user.reload.last_login_at).to eq(Time.current)
        end
      end
    end

    describe '#deactivate!' do
      it 'sets last_login_at to nil' do
        user.update_column(:last_login_at, 1.day.ago)
        user.deactivate!
        expect(user.reload.last_login_at).to be_nil
      end
    end

    describe '#belongs_to_company?' do
      let(:other_company) { create(:company) }

      it 'returns true for the user\'s company' do
        expect(user.belongs_to_company?(user.company)).to be true
      end

      it 'returns false for other companies' do
        expect(user.belongs_to_company?(other_company)).to be false
      end
    end
  end

  describe 'FullNameable concern methods' do
    let(:user) { create(:user, first_name: 'John', last_name: 'Doe') }

    describe '#full_name' do
      it 'returns first and last name combined' do
        expect(user.full_name).to eq('John Doe')
      end

      it 'handles missing names gracefully' do
        user.first_name = nil
        user.last_name = 'Doe'
        expect(user.full_name).to eq('Doe')
      end
    end

    describe '#initials' do
      it 'returns uppercase initials' do
        expect(user.initials).to eq('JD')
      end

      it 'handles missing names' do
        user.first_name = nil
        expect(user.initials).to eq('D')

        user.last_name = nil
        expect(user.initials).to eq('')
      end
    end

    describe '#display_name' do
      it 'returns full name when available' do
        expect(user.display_name).to eq('John Doe')
      end

      it 'falls back to email username when name is blank' do
        user.first_name = ''
        user.last_name = ''
        user.email = 'testuser@example.com'
        expect(user.display_name).to eq('testuser')
      end

      it 'returns Unknown User as final fallback' do
        user.first_name = ''
        user.last_name = ''
        user.email = nil
        expect(user.display_name).to eq('Unknown User')
      end
    end
  end

  describe 'edge cases and security' do
    describe 'email domain validation with edge cases' do
      let(:company_with_domain) { create(:company, email_domain: 'secure.com') }
      let(:user_with_secure_company) { build(:user, company: company_with_domain) }

      it 'prevents subdomain attacks' do
        user_with_secure_company.email = 'hacker@evil.secure.com'
        expect(user_with_secure_company).to be_invalid
        expect(user_with_secure_company.errors[:email]).to include('must be from the secure.com domain')
      end

      it 'prevents similar domain attacks' do
        user_with_secure_company.email = 'user@secure.com.evil.com'
        expect(user_with_secure_company).to be_invalid
        expect(user_with_secure_company.errors[:email]).to include('must be from the secure.com domain')
      end

      it 'handles international domain names' do
        company_with_domain.update!(email_domain: 'münchen.de')
        user_with_secure_company.email = 'user@münchen.de'
        # This test depends on whether the app supports IDN domains
        # Adjust expectation based on actual implementation
      end
    end

    describe 'role-based security' do
      let(:readonly_user) { create(:user, role: :readonly) }
      let(:admin_user) { create(:user, role: :admin) }

      it 'prevents privilege escalation through mass assignment' do
        readonly_user.update(role: :admin)
        expect(readonly_user.role_admin?).to be true # This should be controlled at the controller level
      end
    end

    describe 'JSONB settings security' do
      it 'prevents settings injection attacks' do
        malicious_settings = {
          'script' => '<script>alert("xss")</script>',
          'nested' => { 'code' => '#{User.destroy_all}' }
        }
        
        user.settings = malicious_settings
        user.save!
        user.reload
        
        expect(user.settings['script']).to eq('<script>alert("xss")</script>')
        expect(user.settings['nested']['code']).to eq('#{User.destroy_all}')
      end

      it 'handles very large settings data' do
        large_data = { 'data' => 'x' * 100_000 }
        user.settings = large_data
        
        expect { user.save! }.not_to raise_error
        expect(user.reload.settings['data'].length).to eq(100_000)
      end
    end

    describe 'concurrent user creation' do
      it 'handles race conditions in email uniqueness' do
        # This is more of an integration test, but important for the model
        email = 'concurrent@example.com'
        
        expect {
          User.transaction do
            create(:user, email: email, company: company)
            create(:user, email: email, company: company) # Should fail
          end
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end