# frozen_string_literal: true

RSpec.describe Candidate, type: :model do
  subject(:candidate) { build(:candidate) }

  # Associations
  describe 'associations' do
    it { is_expected.to have_many(:applications).dependent(:destroy) }
    it { is_expected.to have_many(:jobs).through(:applications) }
    it { is_expected.to have_many(:interviews).through(:applications) }
  end

  # Validations
  describe 'validations' do
    context 'required fields' do
      it { is_expected.to validate_presence_of(:email) }
      it { is_expected.to validate_presence_of(:first_name) }
      it { is_expected.to validate_presence_of(:last_name) }
    end

    context 'email validations' do
      it { is_expected.to validate_uniqueness_of(:email) }
      it { is_expected.to allow_value('user@example.com').for(:email) }
      it { is_expected.to allow_value('test.email+tag@domain.co.uk').for(:email) }
      it { is_expected.not_to allow_value('invalid_email').for(:email) }
      it { is_expected.not_to allow_value('user@').for(:email) }
      it { is_expected.not_to allow_value('@example.com').for(:email) }
    end

    context 'name validations' do
      it { is_expected.to validate_length_of(:first_name).is_at_least(1).is_at_most(50) }
      it { is_expected.to validate_length_of(:last_name).is_at_least(1).is_at_most(100) }
    end

    context 'phone validation' do
      it { is_expected.to allow_value('+1 (555) 123-4567').for(:phone) }
      it { is_expected.to allow_value('555-123-4567').for(:phone) }
      it { is_expected.to allow_value('+44 20 1234 5678').for(:phone) }
      it { is_expected.to allow_value('555.123.4567').for(:phone) }
      it { is_expected.to allow_value('(555) 123-4567').for(:phone) }
      it { is_expected.not_to allow_value('invalid phone').for(:phone) }
      it { is_expected.not_to allow_value('123abc456').for(:phone) }
    end

    context 'URL validations' do
      describe 'linkedin_url' do
        it { is_expected.to allow_value('https://linkedin.com/in/johndoe').for(:linkedin_url) }
        it { is_expected.to allow_value('http://www.linkedin.com/in/jane-smith/').for(:linkedin_url) }
        it { is_expected.to allow_value('https://www.linkedin.com/in/user-name-123').for(:linkedin_url) }
        it { is_expected.not_to allow_value('https://facebook.com/johndoe').for(:linkedin_url) }
        it { is_expected.not_to allow_value('linkedin.com/in/johndoe').for(:linkedin_url) }
        it { is_expected.not_to allow_value('invalid_url').for(:linkedin_url) }
      end

      describe 'github_url' do
        it { is_expected.to allow_value('https://github.com/johndoe').for(:github_url) }
        it { is_expected.to allow_value('http://www.github.com/jane-smith/').for(:github_url) }
        it { is_expected.to allow_value('https://github.com/user-name-123').for(:github_url) }
        it { is_expected.not_to allow_value('https://gitlab.com/johndoe').for(:github_url) }
        it { is_expected.not_to allow_value('github.com/johndoe').for(:github_url) }
        it { is_expected.not_to allow_value('invalid_url').for(:github_url) }
      end

      describe 'portfolio_url' do
        it { is_expected.to allow_value('https://johndoe.com').for(:portfolio_url) }
        it { is_expected.to allow_value('http://www.portfolio.example.com').for(:portfolio_url) }
        it { is_expected.to allow_value('https://subdomain.domain.co.uk/portfolio').for(:portfolio_url) }
        it { is_expected.not_to allow_value('invalid_url').for(:portfolio_url) }
        it { is_expected.not_to allow_value('johndoe.com').for(:portfolio_url) }
      end
    end

    context 'numerical validations' do
      describe 'years_of_experience' do
        it { is_expected.to validate_numericality_of(:years_of_experience).is_greater_than_or_equal_to(0) }
        it { is_expected.to validate_numericality_of(:years_of_experience).is_less_than(70) }
        it { is_expected.to allow_value(nil).for(:years_of_experience) }
        
        it 'allows valid experience values' do
          expect(build(:candidate, years_of_experience: 0)).to be_valid
          expect(build(:candidate, years_of_experience: 25)).to be_valid
          expect(build(:candidate, years_of_experience: 69)).to be_valid
        end

        it 'rejects invalid experience values' do
          expect(build(:candidate, years_of_experience: -1)).not_to be_valid
          expect(build(:candidate, years_of_experience: 70)).not_to be_valid
        end
      end

      describe 'salary validations' do
        it { is_expected.to validate_numericality_of(:current_salary).is_greater_than_or_equal_to(0).allow_nil }
        it { is_expected.to validate_numericality_of(:desired_salary_min).is_greater_than_or_equal_to(0).allow_nil }
        it { is_expected.to validate_numericality_of(:desired_salary_max).is_greater_than_or_equal_to(0).allow_nil }

        it 'validates desired_salary_max is greater than desired_salary_min' do
          candidate.desired_salary_min = 100_000
          candidate.desired_salary_max = 80_000
          expect(candidate).not_to be_valid
          expect(candidate.errors[:desired_salary_max]).to include('must be greater than minimum desired salary')
        end

        it 'allows equal desired salary values' do
          candidate.desired_salary_min = 80_000
          candidate.desired_salary_max = 80_000
          expect(candidate).not_to be_valid
          expect(candidate.errors[:desired_salary_max]).to include('must be greater than minimum desired salary')
        end

        it 'allows nil salary values' do
          candidate.desired_salary_min = nil
          candidate.desired_salary_max = nil
          candidate.current_salary = nil
          expect(candidate).to be_valid
        end
      end
    end

    context 'field length validations' do
      it { is_expected.to validate_length_of(:location).is_at_most(100).allow_blank }
      it { is_expected.to validate_length_of(:bio).is_at_most(2000).allow_blank }
      it { is_expected.to validate_length_of(:current_job_title).is_at_most(100).allow_blank }
      it { is_expected.to validate_length_of(:current_company).is_at_most(100).allow_blank }
    end
  end

  # Enums
  describe 'enums' do
    describe 'work_authorization' do
      it { is_expected.to define_enum_for(:work_authorization).with_values(
        'citizen' => 'citizen',
        'permanent_resident' => 'permanent_resident',
        'work_visa' => 'work_visa',
        'student_visa' => 'student_visa',
        'needs_sponsorship' => 'needs_sponsorship'
      ).with_prefix(true) }

      it 'provides predicate methods' do
        candidate = build(:candidate, work_authorization: 'citizen')
        expect(candidate).to be_work_authorization_citizen
        expect(candidate).not_to be_work_authorization_needs_sponsorship
      end
    end

    describe 'notice_period' do
      it { is_expected.to define_enum_for(:notice_period).with_values(
        'immediate' => 'immediate',
        'two_weeks' => 'two_weeks',
        'one_month' => 'one_month',
        'two_months' => 'two_months',
        'three_months' => 'three_months',
        'other' => 'other'
      ).with_prefix(true) }

      it 'provides predicate methods' do
        candidate = build(:candidate, notice_period: 'immediate')
        expect(candidate).to be_notice_period_immediate
        expect(candidate).not_to be_notice_period_two_weeks
      end
    end
  end

  # Scopes
  describe 'scopes' do
    let!(:us_citizen) { create(:candidate, work_authorization: 'citizen') }
    let!(:visa_holder) { create(:candidate, work_authorization: 'work_visa') }
    let!(:immediate_candidate) { create(:candidate, notice_period: 'immediate') }
    let!(:one_month_candidate) { create(:candidate, notice_period: 'one_month') }
    let!(:nyc_candidate) { create(:candidate, location: 'New York, NY') }
    let!(:sf_candidate) { create(:candidate, location: 'San Francisco, CA') }
    let!(:high_salary_candidate) { create(:candidate, desired_salary_min: 120_000, desired_salary_max: 150_000) }
    let!(:low_salary_candidate) { create(:candidate, desired_salary_min: 60_000, desired_salary_max: 80_000) }
    let!(:senior_candidate) { create(:candidate, years_of_experience: 10) }
    let!(:junior_candidate) { create(:candidate, years_of_experience: 2) }
    let!(:remote_candidate) { create(:candidate, open_to_remote: true) }
    let!(:relocate_candidate) { create(:candidate, willing_to_relocate: true) }
    let!(:available_candidate) { create(:candidate, available_for_interview: true) }
    let!(:marketing_consent_candidate) { create(:candidate, marketing_consent: true) }
    let!(:processing_consent_candidate) { create(:candidate, data_processing_consent: true) }
    let!(:recent_candidate) { create(:candidate, created_at: 1.day.ago) }
    let!(:old_candidate) { create(:candidate, created_at: 1.month.ago) }
    let!(:active_candidate) { create(:candidate, deleted_at: nil, last_activity_at: 1.day.ago) }
    let!(:deleted_candidate) { create(:candidate, deleted_at: 1.day.ago) }
    let!(:inactive_candidate) { create(:candidate, last_activity_at: 2.months.ago) }

    describe '.by_work_authorization' do
      it 'filters candidates by work authorization status' do
        expect(Candidate.by_work_authorization('citizen')).to include(us_citizen)
        expect(Candidate.by_work_authorization('work_visa')).to include(visa_holder)
        expect(Candidate.by_work_authorization('citizen')).not_to include(visa_holder)
      end
    end

    describe '.by_notice_period' do
      it 'filters candidates by notice period' do
        expect(Candidate.by_notice_period('immediate')).to include(immediate_candidate)
        expect(Candidate.by_notice_period('one_month')).to include(one_month_candidate)
        expect(Candidate.by_notice_period('immediate')).not_to include(one_month_candidate)
      end
    end

    describe '.by_location' do
      it 'filters candidates by location with case insensitive search' do
        expect(Candidate.by_location('New York')).to include(nyc_candidate)
        expect(Candidate.by_location('new york')).to include(nyc_candidate)
        expect(Candidate.by_location('San Francisco')).to include(sf_candidate)
        expect(Candidate.by_location('New York')).not_to include(sf_candidate)
      end
    end

    describe '.with_salary_range' do
      it 'filters candidates within desired salary range' do
        expect(Candidate.with_salary_range(100_000, 200_000)).to include(high_salary_candidate)
        expect(Candidate.with_salary_range(50_000, 90_000)).to include(low_salary_candidate)
        expect(Candidate.with_salary_range(100_000, 200_000)).not_to include(low_salary_candidate)
      end
    end

    describe '.with_current_salary' do
      let!(:high_current_salary) { create(:candidate, current_salary: 130_000) }
      let!(:low_current_salary) { create(:candidate, current_salary: 70_000) }

      it 'filters candidates by current salary range' do
        expect(Candidate.with_current_salary(100_000, 150_000)).to include(high_current_salary)
        expect(Candidate.with_current_salary(50_000, 90_000)).to include(low_current_salary)
        expect(Candidate.with_current_salary(100_000, 150_000)).not_to include(low_current_salary)
      end
    end

    describe '.by_experience_years' do
      it 'filters candidates by years of experience range' do
        expect(Candidate.by_experience_years(5, 15)).to include(senior_candidate)
        expect(Candidate.by_experience_years(0, 5)).to include(junior_candidate)
        expect(Candidate.by_experience_years(5, 15)).not_to include(junior_candidate)
      end
    end

    describe '.recent' do
      it 'orders candidates by creation date descending' do
        expect(Candidate.recent.first).to eq(recent_candidate)
      end
    end

    describe '.alphabetical' do
      let!(:alice) { create(:candidate, first_name: 'Alice', last_name: 'Smith') }
      let!(:bob) { create(:candidate, first_name: 'Bob', last_name: 'Johnson') }
      let!(:charlie) { create(:candidate, first_name: 'Charlie', last_name: 'Brown') }

      it 'orders candidates alphabetically by last name then first name' do
        alphabetical = Candidate.alphabetical.where(id: [alice.id, bob.id, charlie.id])
        expect(alphabetical.pluck(:id)).to eq([charlie.id, bob.id, alice.id])
      end
    end

    describe '.active' do
      it 'returns only non-deleted candidates' do
        expect(Candidate.active).to include(active_candidate)
        expect(Candidate.active).not_to include(deleted_candidate)
      end
    end

    describe '.recently_active' do
      it 'returns candidates active within the last 30 days' do
        expect(Candidate.recently_active).to include(active_candidate)
        expect(Candidate.recently_active).not_to include(inactive_candidate)
      end
    end

    describe '.open_to_remote' do
      it 'returns candidates open to remote work' do
        expect(Candidate.open_to_remote).to include(remote_candidate)
        expect(Candidate.open_to_remote).not_to include(nyc_candidate)
      end
    end

    describe '.willing_to_relocate' do
      it 'returns candidates willing to relocate' do
        expect(Candidate.willing_to_relocate).to include(relocate_candidate)
        expect(Candidate.willing_to_relocate).not_to include(nyc_candidate)
      end
    end

    describe '.available_for_interview' do
      it 'returns candidates available for interviews' do
        expect(Candidate.available_for_interview).to include(available_candidate)
      end
    end

    describe '.with_marketing_consent' do
      it 'returns candidates who consented to marketing' do
        expect(Candidate.with_marketing_consent).to include(marketing_consent_candidate)
        expect(Candidate.with_marketing_consent).not_to include(us_citizen)
      end
    end

    describe '.with_data_processing_consent' do
      it 'returns candidates who consented to data processing' do
        expect(Candidate.with_data_processing_consent).to include(processing_consent_candidate)
        expect(Candidate.with_data_processing_consent).not_to include(us_citizen)
      end
    end

    describe '.with_resume' do
      let!(:candidate_with_resume) { create(:candidate, resume_url: 'https://example.com/resume.pdf') }
      let!(:candidate_without_resume) { create(:candidate, resume_url: nil) }

      it 'returns candidates with resume URLs' do
        expect(Candidate.with_resume).to include(candidate_with_resume)
        expect(Candidate.with_resume).not_to include(candidate_without_resume)
      end
    end

    describe '.with_skills' do
      let!(:ruby_candidate) { create(:candidate, skills: ['Ruby', 'Rails', 'PostgreSQL']) }
      let!(:js_candidate) { create(:candidate, skills: ['JavaScript', 'React', 'Node.js']) }

      it 'finds candidates with matching skills' do
        expect(Candidate.with_skills(['Ruby'])).to include(ruby_candidate)
        expect(Candidate.with_skills(['JavaScript'])).to include(js_candidate)
        expect(Candidate.with_skills(['Ruby'])).not_to include(js_candidate)
      end

      it 'handles array of skills' do
        expect(Candidate.with_skills(['Ruby', 'Rails'])).to include(ruby_candidate)
      end
    end

    describe '.with_certifications' do
      let!(:aws_candidate) { create(:candidate, certifications: ['AWS Solutions Architect', 'AWS Developer']) }
      let!(:azure_candidate) { create(:candidate, certifications: ['Azure Administrator', 'Azure Developer']) }

      it 'finds candidates with matching certifications' do
        expect(Candidate.with_certifications(['AWS Solutions Architect'])).to include(aws_candidate)
        expect(Candidate.with_certifications(['Azure Administrator'])).to include(azure_candidate)
        expect(Candidate.with_certifications(['AWS Solutions Architect'])).not_to include(azure_candidate)
      end
    end

    describe '.speaks_language' do
      let!(:multilingual_candidate) { create(:candidate, languages: {'English' => 'native', 'Spanish' => 'fluent', 'French' => 'basic'}) }
      let!(:english_only_candidate) { create(:candidate, languages: {'English' => 'native'}) }

      it 'finds candidates who speak specific languages' do
        expect(Candidate.speaks_language('English')).to include(multilingual_candidate, english_only_candidate)
        expect(Candidate.speaks_language('Spanish')).to include(multilingual_candidate)
        expect(Candidate.speaks_language('Spanish')).not_to include(english_only_candidate)
      end
    end
  end

  # Search scopes
  describe 'search scopes' do
    let!(:john_doe) { create(:candidate, first_name: 'John', last_name: 'Doe', email: 'john.doe@example.com') }
    let!(:jane_smith) { create(:candidate, first_name: 'Jane', last_name: 'Smith', email: 'jane.smith@example.com') }
    let!(:developer_candidate) { create(:candidate, 
      bio: 'Experienced Ruby developer with 5 years of experience',
      current_job_title: 'Senior Software Engineer',
      current_company: 'Tech Corp',
      resume_text: 'Ruby on Rails, JavaScript, PostgreSQL'
    ) }

    describe '.search_by_name' do
      it 'finds candidates by first name' do
        expect(Candidate.search_by_name('John')).to include(john_doe)
        expect(Candidate.search_by_name('john')).to include(john_doe)
        expect(Candidate.search_by_name('Jane')).to include(jane_smith)
      end

      it 'finds candidates by last name' do
        expect(Candidate.search_by_name('Doe')).to include(john_doe)
        expect(Candidate.search_by_name('Smith')).to include(jane_smith)
      end

      it 'finds candidates by full name' do
        expect(Candidate.search_by_name('John Doe')).to include(john_doe)
        expect(Candidate.search_by_name('jane smith')).to include(jane_smith)
      end
    end

    describe '.search_by_email' do
      it 'finds candidates by email' do
        expect(Candidate.search_by_email('john.doe')).to include(john_doe)
        expect(Candidate.search_by_email('jane.smith')).to include(jane_smith)
        expect(Candidate.search_by_email('example.com')).to include(john_doe, jane_smith)
      end
    end

    describe '.search_by_content' do
      it 'searches across bio, job title, company, and resume text' do
        expect(Candidate.search_by_content('Ruby')).to include(developer_candidate)
        expect(Candidate.search_by_content('Senior Software Engineer')).to include(developer_candidate)
        expect(Candidate.search_by_content('Tech Corp')).to include(developer_candidate)
        expect(Candidate.search_by_content('PostgreSQL')).to include(developer_candidate)
      end

      it 'performs case-insensitive search' do
        expect(Candidate.search_by_content('ruby')).to include(developer_candidate)
        expect(Candidate.search_by_content('RUBY')).to include(developer_candidate)
      end
    end

    describe '.search_by_skills' do
      let!(:ruby_candidate) { create(:candidate, skills: ['Ruby', 'Rails', 'PostgreSQL']) }
      let!(:js_candidate) { create(:candidate, skills: ['JavaScript', 'React', 'Node.js']) }

      it 'finds candidates with matching skills' do
        expect(Candidate.search_by_skills(['Ruby'])).to include(ruby_candidate)
        expect(Candidate.search_by_skills(['JavaScript'])).to include(js_candidate)
        expect(Candidate.search_by_skills(['Ruby'])).not_to include(js_candidate)
      end
    end
  end

  # Business Logic Methods
  describe 'business logic methods' do
    describe '#full_name' do
      it 'combines first and last name' do
        candidate = build(:candidate, first_name: 'John', last_name: 'Doe')
        expect(candidate.full_name).to eq('John Doe')
      end

      it 'handles extra whitespace' do
        candidate = build(:candidate, first_name: ' John ', last_name: ' Doe ')
        expect(candidate.full_name).to eq('John   Doe')
      end
    end

    describe '#initials' do
      it 'returns uppercased initials' do
        candidate = build(:candidate, first_name: 'john', last_name: 'doe')
        expect(candidate.initials).to eq('JD')
      end

      it 'handles single character names' do
        candidate = build(:candidate, first_name: 'A', last_name: 'B')
        expect(candidate.initials).to eq('AB')
      end
    end

    describe '#formatted_current_salary' do
      context 'with current salary and currency' do
        it 'formats USD salary' do
          candidate = build(:candidate, current_salary: 120_000, current_salary_currency: 'USD')
          expect(candidate.formatted_current_salary).to eq('$120,000')
        end

        it 'formats EUR salary' do
          candidate = build(:candidate, current_salary: 100_000, current_salary_currency: 'EUR')
          expect(candidate.formatted_current_salary).to eq('€100,000')
        end

        it 'formats GBP salary' do
          candidate = build(:candidate, current_salary: 80_000, current_salary_currency: 'GBP')
          expect(candidate.formatted_current_salary).to eq('£80,000')
        end

        it 'formats other currencies' do
          candidate = build(:candidate, current_salary: 50_000, current_salary_currency: 'CAD')
          expect(candidate.formatted_current_salary).to eq('50,000 CAD')
        end
      end

      context 'without current salary' do
        it 'returns default message' do
          candidate = build(:candidate, current_salary: nil)
          expect(candidate.formatted_current_salary).to eq('Not specified')
        end
      end
    end

    describe '#formatted_desired_salary_range' do
      context 'with both min and max desired salary' do
        it 'formats salary range with specified currency' do
          candidate = build(:candidate, 
            desired_salary_min: 100_000, 
            desired_salary_max: 130_000,
            desired_salary_currency: 'USD'
          )
          expect(candidate.formatted_desired_salary_range).to eq('$100,000 - $130,000')
        end

        it 'defaults to USD when no currency specified' do
          candidate = build(:candidate, 
            desired_salary_min: 100_000, 
            desired_salary_max: 130_000,
            desired_salary_currency: nil
          )
          expect(candidate.formatted_desired_salary_range).to eq('$100,000 - $130,000')
        end
      end

      context 'with only minimum desired salary' do
        it 'shows minimum salary format' do
          candidate = build(:candidate, 
            desired_salary_min: 100_000, 
            desired_salary_max: nil,
            desired_salary_currency: 'USD'
          )
          expect(candidate.formatted_desired_salary_range).to eq('From $100,000')
        end
      end

      context 'with only maximum desired salary' do
        it 'shows maximum salary format' do
          candidate = build(:candidate, 
            desired_salary_min: nil, 
            desired_salary_max: 130_000,
            desired_salary_currency: 'USD'
          )
          expect(candidate.formatted_desired_salary_range).to eq('Up to $130,000')
        end
      end

      context 'without desired salary information' do
        it 'returns default message' do
          candidate = build(:candidate, desired_salary_min: nil, desired_salary_max: nil)
          expect(candidate.formatted_desired_salary_range).to eq('Not specified')
        end
      end
    end

    describe 'humanized enum methods' do
      describe '#work_authorization_humanized' do
        it 'converts enum values to human readable format' do
          expect(build(:candidate, work_authorization: 'citizen').work_authorization_humanized).to eq('Citizen')
          expect(build(:candidate, work_authorization: 'permanent_resident').work_authorization_humanized).to eq('Permanent Resident')
          expect(build(:candidate, work_authorization: 'work_visa').work_authorization_humanized).to eq('Work Visa')
          expect(build(:candidate, work_authorization: 'student_visa').work_authorization_humanized).to eq('Student Visa')
          expect(build(:candidate, work_authorization: 'needs_sponsorship').work_authorization_humanized).to eq('Needs Sponsorship')
        end

        it 'handles nil work authorization' do
          candidate = build(:candidate, work_authorization: nil)
          expect(candidate.work_authorization_humanized).to be_nil
        end
      end

      describe '#notice_period_humanized' do
        it 'converts enum values to human readable format' do
          expect(build(:candidate, notice_period: 'immediate').notice_period_humanized).to eq('Available immediately')
          expect(build(:candidate, notice_period: 'two_weeks').notice_period_humanized).to eq('Available in 2 weeks')
          expect(build(:candidate, notice_period: 'one_month').notice_period_humanized).to eq('Available in 1 month')
          expect(build(:candidate, notice_period: 'two_months').notice_period_humanized).to eq('Available in 2 months')
          expect(build(:candidate, notice_period: 'three_months').notice_period_humanized).to eq('Available in 3 months')
          expect(build(:candidate, notice_period: 'other').notice_period_humanized).to eq('Other availability')
        end
      end
    end

    describe '#profile_completeness_percentage' do
      it 'calculates percentage based on filled fields' do
        complete_candidate = build(:candidate,
          first_name: 'John',
          last_name: 'Doe',
          email: 'john@example.com',
          phone: '555-123-4567',
          location: 'New York, NY',
          linkedin_url: 'https://linkedin.com/in/johndoe',
          portfolio_url: 'https://johndoe.com',
          github_url: 'https://github.com/johndoe',
          bio: 'Experienced developer',
          current_job_title: 'Senior Developer',
          current_company: 'Tech Corp',
          years_of_experience: 5,
          current_salary: 120_000,
          desired_salary_min: 130_000,
          work_authorization: 'citizen',
          notice_period: 'two_weeks',
          resume_url: 'https://example.com/resume.pdf',
          skills: ['Ruby', 'Rails'],
          certifications: ['AWS'],
          languages: {'English' => 'native'}
        )
        
        expect(complete_candidate.profile_completeness_percentage).to eq(100)
      end

      it 'calculates lower percentage for incomplete profiles' do
        minimal_candidate = build(:candidate,
          first_name: 'John',
          last_name: 'Doe', 
          email: 'john@example.com'
        )
        
        expect(minimal_candidate.profile_completeness_percentage).to eq(15) # 3 out of 20 fields
      end
    end

    describe 'boolean check methods' do
      describe '#has_complete_contact_info?' do
        it 'returns true when email, phone, and location are present' do
          candidate = build(:candidate, email: 'test@example.com', phone: '555-123-4567', location: 'NYC')
          expect(candidate.has_complete_contact_info?).to be true
        end

        it 'returns false when any contact info is missing' do
          expect(build(:candidate, email: 'test@example.com', phone: nil, location: 'NYC').has_complete_contact_info?).to be false
          expect(build(:candidate, email: 'test@example.com', phone: '555-123-4567', location: nil).has_complete_contact_info?).to be false
        end
      end

      describe '#needs_visa_sponsorship?' do
        it 'returns true for candidates needing sponsorship' do
          candidate = build(:candidate, work_authorization: 'needs_sponsorship')
          expect(candidate.needs_visa_sponsorship?).to be true
        end

        it 'returns false for citizens and permanent residents' do
          expect(build(:candidate, work_authorization: 'citizen').needs_visa_sponsorship?).to be false
          expect(build(:candidate, work_authorization: 'permanent_resident').needs_visa_sponsorship?).to be false
        end
      end

      describe '#available_immediately?' do
        it 'returns true for immediate availability' do
          candidate = build(:candidate, notice_period: 'immediate')
          expect(candidate.available_immediately?).to be true
        end

        it 'returns false for other notice periods' do
          candidate = build(:candidate, notice_period: 'two_weeks')
          expect(candidate.available_immediately?).to be false
        end
      end

      describe '#experience_in_years' do
        it 'returns years of experience or 0 if nil' do
          expect(build(:candidate, years_of_experience: 5).experience_in_years).to eq(5)
          expect(build(:candidate, years_of_experience: nil).experience_in_years).to eq(0)
        end
      end

      describe '#has_resume?' do
        it 'returns true when resume_url is present' do
          candidate = build(:candidate, resume_url: 'https://example.com/resume.pdf')
          expect(candidate.has_resume?).to be true
        end

        it 'returns false when resume_url is blank' do
          expect(build(:candidate, resume_url: nil).has_resume?).to be false
          expect(build(:candidate, resume_url: '').has_resume?).to be false
        end
      end

      describe '#is_active?' do
        it 'returns true for non-deleted candidates' do
          candidate = build(:candidate, deleted_at: nil)
          expect(candidate.is_active?).to be true
        end

        it 'returns false for deleted candidates' do
          candidate = build(:candidate, deleted_at: 1.day.ago)
          expect(candidate.is_active?).to be false
        end
      end

      describe '#recently_active?' do
        it 'returns true for candidates active within 30 days' do
          candidate = build(:candidate, last_activity_at: 1.day.ago)
          expect(candidate.recently_active?).to be true
        end

        it 'returns false for candidates inactive for over 30 days' do
          candidate = build(:candidate, last_activity_at: 31.days.ago)
          expect(candidate.recently_active?).to be false
        end

        it 'returns false when last_activity_at is nil' do
          candidate = build(:candidate, last_activity_at: nil)
          expect(candidate.recently_active?).to be false
        end
      end

      describe '#consented_to_marketing?' do
        it 'returns true when marketing consent is true and timestamp exists' do
          candidate = build(:candidate, marketing_consent: true, marketing_consent_at: 1.day.ago)
          expect(candidate.consented_to_marketing?).to be true
        end

        it 'returns false when consent is true but no timestamp' do
          candidate = build(:candidate, marketing_consent: true, marketing_consent_at: nil)
          expect(candidate.consented_to_marketing?).to be false
        end

        it 'returns false when consent is false' do
          candidate = build(:candidate, marketing_consent: false, marketing_consent_at: 1.day.ago)
          expect(candidate.consented_to_marketing?).to be false
        end
      end

      describe '#consented_to_data_processing?' do
        it 'returns true when data processing consent is true and timestamp exists' do
          candidate = build(:candidate, data_processing_consent: true, data_processing_consent_at: 1.day.ago)
          expect(candidate.consented_to_data_processing?).to be true
        end

        it 'returns false when consent is true but no timestamp' do
          candidate = build(:candidate, data_processing_consent: true, data_processing_consent_at: nil)
          expect(candidate.consented_to_data_processing?).to be false
        end

        it 'returns false when consent is false' do
          candidate = build(:candidate, data_processing_consent: false, data_processing_consent_at: 1.day.ago)
          expect(candidate.consented_to_data_processing?).to be false
        end
      end
    end
  end

  # JSONB Field Handling
  describe 'JSONB field handling' do
    describe '#skills_list' do
      it 'returns empty array when skills is nil' do
        candidate = build(:candidate, skills: nil)
        expect(candidate.skills_list).to eq([])
      end

      it 'returns empty array when skills is not an array' do
        candidate = build(:candidate, skills: 'not an array')
        expect(candidate.skills_list).to eq([])
      end

      it 'returns skills array when properly formatted' do
        skills = ['Ruby', 'Rails', 'JavaScript']
        candidate = build(:candidate, skills: skills)
        expect(candidate.skills_list).to eq(skills)
      end
    end

    describe 'skills management methods' do
      let(:candidate) { create(:candidate, skills: ['Ruby', 'Rails']) }

      describe '#add_skill' do
        it 'adds a new skill' do
          candidate.add_skill('JavaScript')
          expect(candidate.reload.skills_list).to include('JavaScript')
        end

        it 'does not add duplicate skills' do
          original_count = candidate.skills_list.count
          candidate.add_skill('Ruby')
          expect(candidate.reload.skills_list.count).to eq(original_count)
        end

        it 'saves the candidate' do
          expect(candidate).to receive(:save)
          candidate.add_skill('JavaScript')
        end
      end

      describe '#remove_skill' do
        it 'removes an existing skill' do
          candidate.remove_skill('Ruby')
          expect(candidate.reload.skills_list).not_to include('Ruby')
        end

        it 'saves the candidate' do
          expect(candidate).to receive(:save)
          candidate.remove_skill('Ruby')
        end
      end
    end

    describe '#certifications_list' do
      it 'returns empty array when certifications is nil' do
        candidate = build(:candidate, certifications: nil)
        expect(candidate.certifications_list).to eq([])
      end

      it 'returns certifications array when properly formatted' do
        certs = ['AWS Solutions Architect', 'Scrum Master']
        candidate = build(:candidate, certifications: certs)
        expect(candidate.certifications_list).to eq(certs)
      end
    end

    describe 'certifications management methods' do
      let(:candidate) { create(:candidate, certifications: ['AWS Solutions Architect']) }

      describe '#add_certification' do
        it 'adds a new certification' do
          candidate.add_certification('Azure Developer')
          expect(candidate.reload.certifications_list).to include('Azure Developer')
        end

        it 'does not add duplicate certifications' do
          original_count = candidate.certifications_list.count
          candidate.add_certification('AWS Solutions Architect')
          expect(candidate.reload.certifications_list.count).to eq(original_count)
        end
      end

      describe '#remove_certification' do
        it 'removes an existing certification' do
          candidate.remove_certification('AWS Solutions Architect')
          expect(candidate.reload.certifications_list).not_to include('AWS Solutions Architect')
        end
      end
    end

    describe '#languages_list' do
      it 'returns empty hash when languages is nil' do
        candidate = build(:candidate, languages: nil)
        expect(candidate.languages_list).to eq({})
      end

      it 'returns empty hash when languages is not a hash' do
        candidate = build(:candidate, languages: 'not a hash')
        expect(candidate.languages_list).to eq({})
      end

      it 'returns languages hash when properly formatted' do
        languages = {'English' => 'native', 'Spanish' => 'fluent'}
        candidate = build(:candidate, languages: languages)
        expect(candidate.languages_list).to eq(languages)
      end
    end

    describe 'languages management methods' do
      let(:candidate) { create(:candidate, languages: {'English' => 'native'}) }

      describe '#add_language' do
        it 'adds a new language with default proficiency' do
          candidate.add_language('Spanish')
          expect(candidate.reload.languages_list['Spanish']).to eq('basic')
        end

        it 'adds a new language with specified proficiency' do
          candidate.add_language('French', 'fluent')
          expect(candidate.reload.languages_list['French']).to eq('fluent')
        end

        it 'updates existing language proficiency' do
          candidate.add_language('English', 'fluent')
          expect(candidate.reload.languages_list['English']).to eq('fluent')
        end
      end

      describe '#remove_language' do
        it 'removes an existing language' do
          candidate.remove_language('English')
          expect(candidate.reload.languages_list).not_to have_key('English')
        end
      end
    end

    describe 'preference lists' do
      describe '#preferred_work_types_list' do
        it 'returns empty array when nil' do
          candidate = build(:candidate, preferred_work_types: nil)
          expect(candidate.preferred_work_types_list).to eq([])
        end

        it 'returns array when properly formatted' do
          types = ['full_time', 'contract']
          candidate = build(:candidate, preferred_work_types: types)
          expect(candidate.preferred_work_types_list).to eq(types)
        end
      end

      describe '#preferred_locations_list' do
        it 'returns empty array when nil' do
          candidate = build(:candidate, preferred_locations: nil)
          expect(candidate.preferred_locations_list).to eq([])
        end

        it 'returns array when properly formatted' do
          locations = ['New York', 'San Francisco', 'Remote']
          candidate = build(:candidate, preferred_locations: locations)
          expect(candidate.preferred_locations_list).to eq(locations)
        end
      end

      describe '#additional_documents_list' do
        it 'returns empty array when nil' do
          candidate = build(:candidate, additional_documents: nil)
          expect(candidate.additional_documents_list).to eq([])
        end

        it 'returns array when properly formatted' do
          docs = [{'name' => 'Portfolio', 'url' => 'https://example.com/portfolio.pdf'}]
          candidate = build(:candidate, additional_documents: docs)
          expect(candidate.additional_documents_list).to eq(docs)
        end
      end
    end
  end

  # GDPR Compliance
  describe 'GDPR compliance' do
    describe '#schedule_gdpr_deletion' do
      it 'sets gdpr_delete_after to specified days from now' do
        candidate = create(:candidate)
        freeze_time do
          candidate.schedule_gdpr_deletion(30)
          expect(candidate.gdpr_delete_after).to be_within(1.second).of(30.days.from_now)
        end
      end

      it 'uses default of 30 days when no argument provided' do
        candidate = create(:candidate)
        freeze_time do
          candidate.schedule_gdpr_deletion
          expect(candidate.gdpr_delete_after).to be_within(1.second).of(30.days.from_now)
        end
      end
    end

    describe '#due_for_gdpr_deletion?' do
      it 'returns true when gdpr_delete_after is in the past' do
        candidate = create(:candidate, gdpr_delete_after: 1.day.ago)
        expect(candidate.due_for_gdpr_deletion?).to be true
      end

      it 'returns false when gdpr_delete_after is in the future' do
        candidate = create(:candidate, gdpr_delete_after: 1.day.from_now)
        expect(candidate.due_for_gdpr_deletion?).to be false
      end

      it 'returns false when gdpr_delete_after is not set' do
        candidate = create(:candidate, gdpr_delete_after: nil)
        expect(candidate.due_for_gdpr_deletion?).to be false
      end
    end

    describe '.gdpr_deletable scope' do
      let!(:due_for_deletion) { create(:candidate, gdpr_delete_after: 1.day.ago) }
      let!(:not_due_for_deletion) { create(:candidate, gdpr_delete_after: 1.day.from_now) }
      let!(:no_deletion_date) { create(:candidate, gdpr_delete_after: nil) }

      it 'returns candidates due for GDPR deletion' do
        expect(Candidate.gdpr_deletable).to include(due_for_deletion)
        expect(Candidate.gdpr_deletable).not_to include(not_due_for_deletion, no_deletion_date)
      end
    end
  end

  # Soft Delete
  describe 'soft delete functionality' do
    describe '#soft_delete!' do
      it 'sets deleted_at timestamp' do
        candidate = create(:candidate)
        freeze_time do
          candidate.soft_delete!
          expect(candidate.deleted_at).to be_within(1.second).of(Time.current)
        end
      end

      it 'persists the change' do
        candidate = create(:candidate)
        candidate.soft_delete!
        expect(candidate.reload.deleted_at).to be_present
      end
    end

    describe '#restore!' do
      it 'clears deleted_at timestamp for deleted candidates' do
        candidate = create(:candidate, deleted_at: 1.day.ago)
        candidate.restore!
        expect(candidate.deleted_at).to be_nil
      end

      it 'does nothing for non-deleted candidates' do
        candidate = create(:candidate, deleted_at: nil)
        original_updated_at = candidate.updated_at
        candidate.restore!
        expect(candidate.updated_at).to eq(original_updated_at)
      end
    end
  end

  # Callbacks
  describe 'callbacks' do
    describe 'before_save callbacks' do
      describe '#normalize_email' do
        it 'downcases and strips email' do
          candidate = build(:candidate, email: '  JOHN.DOE@EXAMPLE.COM  ')
          candidate.save!
          expect(candidate.email).to eq('john.doe@example.com')
        end
      end

      describe '#normalize_urls' do
        it 'adds https protocol to URLs missing it' do
          candidate = build(:candidate, 
            linkedin_url: 'linkedin.com/in/johndoe',
            portfolio_url: 'johndoe.com',
            github_url: 'github.com/johndoe'
          )
          candidate.save!
          expect(candidate.linkedin_url).to eq('https://linkedin.com/in/johndoe')
          expect(candidate.portfolio_url).to eq('https://johndoe.com')
          expect(candidate.github_url).to eq('https://github.com/johndoe')
        end

        it 'does not modify URLs that already have protocol' do
          candidate = build(:candidate,
            linkedin_url: 'https://linkedin.com/in/johndoe',
            portfolio_url: 'http://johndoe.com'
          )
          candidate.save!
          expect(candidate.linkedin_url).to eq('https://linkedin.com/in/johndoe')
          expect(candidate.portfolio_url).to eq('http://johndoe.com')
        end
      end

      describe '#update_last_activity' do
        it 'sets last_activity_at to current time on save' do
          candidate = build(:candidate)
          freeze_time do
            candidate.save!
            expect(candidate.last_activity_at).to be_within(1.second).of(Time.current)
          end
        end
      end
    end

    describe 'before_create callback' do
      describe '#set_defaults' do
        it 'initializes JSONB fields as empty arrays/hashes' do
          candidate = build(:candidate, 
            skills: nil, 
            languages: nil, 
            certifications: nil,
            preferred_work_types: nil,
            preferred_locations: nil,
            additional_documents: nil
          )
          candidate.save!
          expect(candidate.skills).to eq([])
          expect(candidate.languages).to eq({})
          expect(candidate.certifications).to eq([])
          expect(candidate.preferred_work_types).to eq([])
          expect(candidate.preferred_locations).to eq([])
          expect(candidate.additional_documents).to eq([])
        end

        it 'sets default boolean values' do
          candidate = build(:candidate,
            marketing_consent: nil,
            data_processing_consent: nil,
            available_for_interview: nil,
            open_to_remote: nil,
            willing_to_relocate: nil
          )
          candidate.save!
          expect(candidate.marketing_consent).to be false
          expect(candidate.data_processing_consent).to be false
          expect(candidate.available_for_interview).to be true
          expect(candidate.open_to_remote).to be false
          expect(candidate.willing_to_relocate).to be false
        end
      end
    end
  end

  # Class Methods
  describe 'class methods' do
    describe '.search' do
      let!(:john_doe) { create(:candidate, first_name: 'John', last_name: 'Doe', email: 'john@example.com') }
      let!(:jane_developer) { create(:candidate, 
        first_name: 'Jane', 
        last_name: 'Smith',
        email: 'jane@example.com',
        bio: 'Experienced Ruby developer',
        current_job_title: 'Senior Software Engineer'
      ) }

      it 'returns all candidates when query is blank' do
        expect(Candidate.search('')).to match_array([john_doe, jane_developer])
        expect(Candidate.search(nil)).to match_array([john_doe, jane_developer])
      end

      it 'searches by name, email, and content' do
        expect(Candidate.search('John')).to include(john_doe)
        expect(Candidate.search('jane@example.com')).to include(jane_developer)
        expect(Candidate.search('Ruby developer')).to include(jane_developer)
        expect(Candidate.search('Senior Software')).to include(jane_developer)
      end

      it 'performs case-insensitive search' do
        expect(Candidate.search('john')).to include(john_doe)
        expect(Candidate.search('RUBY')).to include(jane_developer)
      end
    end

    describe '.popular_skills' do
      before do
        create(:candidate, skills: ['Ruby', 'Rails', 'JavaScript'])
        create(:candidate, skills: ['Ruby', 'Python', 'JavaScript'])
        create(:candidate, skills: ['JavaScript', 'React', 'Node.js'])
        create(:candidate, skills: [])
        create(:candidate, skills: nil)
      end

      it 'returns most popular skills in descending order' do
        popular = Candidate.popular_skills
        expect(popular.first).to eq('JavaScript') # appears 3 times
        expect(popular.second).to eq('Ruby') # appears 2 times
        expect(popular).to include('Rails', 'Python', 'React', 'Node.js')
      end

      it 'limits to 20 skills' do
        expect(Candidate.popular_skills.length).to be <= 20
      end
    end
  end

  # Performance Tests
  describe 'performance considerations', :performance do
    it 'efficiently queries JSONB fields' do
      # Create candidates with various skills
      create_list(:candidate, 10, skills: ['Ruby', 'Rails'])
      create_list(:candidate, 10, skills: ['JavaScript', 'React'])
      
      expect {
        Candidate.with_skills(['Ruby']).load
      }.to perform_under(50).ms
    end

    it 'efficiently processes complex scopes' do
      create_list(:candidate, 50)
      
      expect {
        Candidate.active.recently_active.with_data_processing_consent.recent.limit(10).load
      }.to perform_under(50).ms
    end

    it 'efficiently handles language searches' do
      create_list(:candidate, 20, languages: {'English' => 'native', 'Spanish' => 'fluent'})
      
      expect {
        Candidate.speaks_language('English').load
      }.to perform_under(50).ms
    end
  end
end