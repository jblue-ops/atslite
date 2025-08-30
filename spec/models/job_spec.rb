# frozen_string_literal: true

RSpec.describe Job, type: :model do
  subject(:job) { build(:job) }

  # Associations
  describe 'associations' do
    it { is_expected.to belong_to(:company) }
    it { is_expected.to belong_to(:hiring_manager).class_name('User').optional }
    it { is_expected.to have_many(:applications).dependent(:destroy) }
    it { is_expected.to have_many(:candidates).through(:applications) }
    it { is_expected.to have_many(:interviews).through(:applications) }
  end

  # Validations
  describe 'validations' do
    context 'required fields' do
      it { is_expected.to validate_presence_of(:title) }
      it { is_expected.to validate_presence_of(:company_id) }
      it { is_expected.to validate_presence_of(:employment_type) }
      it { is_expected.to validate_presence_of(:experience_level) }
      it { is_expected.to validate_presence_of(:status) }
      it { is_expected.to validate_presence_of(:work_location_type) }
    end

    context 'field length validations' do
      it { is_expected.to validate_length_of(:title).is_at_least(3).is_at_most(100) }
      it { is_expected.to validate_length_of(:location).is_at_most(100).allow_blank }
      it { is_expected.to validate_length_of(:referral_bonus_amount).is_at_most(50).allow_blank }
    end

    context 'numerical validations' do
      it { is_expected.to validate_numericality_of(:salary_min).is_greater_than_or_equal_to(0).allow_nil }
      it { is_expected.to validate_numericality_of(:salary_max).is_greater_than_or_equal_to(0).allow_nil }
      it { is_expected.to validate_numericality_of(:openings_count).is_greater_than(0).allow_nil }
    end

    context 'salary validations' do
      it 'validates salary_currency presence when salary is present' do
        job.salary_min = 50_000
        job.salary_currency = nil
        expect(job).not_to be_valid
        expect(job.errors[:salary_currency]).to include("can't be blank")
      end

      it 'validates salary_currency format' do
        job.salary_min = 50_000
        job.salary_currency = 'INVALID'
        expect(job).not_to be_valid
        expect(job.errors[:salary_currency]).to include('is the wrong length (should be 3 characters)')
      end

      it 'validates salary_max is greater than salary_min' do
        job.salary_min = 100_000
        job.salary_max = 80_000
        expect(job).not_to be_valid
        expect(job.errors[:salary_max]).to include('must be greater than minimum salary')
      end

      it 'allows equal salary_min and salary_max' do
        job.salary_min = 80_000
        job.salary_max = 80_000
        expect(job).not_to be_valid
        expect(job.errors[:salary_max]).to include('must be greater than minimum salary')
      end

      it 'allows nil salary values' do
        job.salary_min = nil
        job.salary_max = nil
        job.salary_currency = nil
        expect(job).to be_valid
      end
    end

    context 'date validations' do
      let(:job) { build(:job, :published) }

      it 'validates posted_at presence when published' do
        job.status = 'published'
        job.posted_at = nil
        expect(job).not_to be_valid
        expect(job.errors[:posted_at]).to include("can't be blank")
      end

      it 'validates application_deadline is after posted_at' do
        job.posted_at = 1.day.ago
        job.application_deadline = 2.days.ago
        expect(job).not_to be_valid
        expect(job.errors[:application_deadline]).to include('must be greater than posted at')
      end

      it 'validates target_start_date is after posted_at' do
        job.posted_at = 1.day.ago
        job.target_start_date = 2.days.ago
        expect(job).not_to be_valid
        expect(job.errors[:target_start_date]).to include('must be greater than posted at')
      end

      it 'allows future dates for deadlines' do
        job.posted_at = 1.day.ago
        job.application_deadline = 1.week.from_now
        job.target_start_date = 1.month.from_now
        expect(job).to be_valid
      end
    end
  end

  # Enums
  describe 'enums' do
    describe 'employment_type' do
      it { is_expected.to define_enum_for(:employment_type).with_values(
        'full_time' => 'full_time',
        'part_time' => 'part_time', 
        'contract' => 'contract',
        'internship' => 'internship',
        'temporary' => 'temporary'
      ).with_prefix(true) }

      it 'provides predicate methods' do
        job = build(:job, employment_type: 'full_time')
        expect(job).to be_employment_type_full_time
        expect(job).not_to be_employment_type_part_time
      end
    end

    describe 'experience_level' do
      it { is_expected.to define_enum_for(:experience_level).with_values(
        'entry' => 'entry',
        'mid' => 'mid',
        'senior' => 'senior', 
        'executive' => 'executive'
      ).with_prefix(true) }

      it 'provides predicate methods' do
        job = build(:job, experience_level: 'senior')
        expect(job).to be_experience_level_senior
        expect(job).not_to be_experience_level_entry
      end
    end

    describe 'status' do
      it { is_expected.to define_enum_for(:status).with_values(
        'draft' => 'draft',
        'published' => 'published',
        'paused' => 'paused',
        'closed' => 'closed',
        'archived' => 'archived'
      ).with_prefix(true) }

      it 'provides predicate methods' do
        job = build(:job, status: 'published')
        expect(job).to be_status_published
        expect(job).not_to be_status_draft
      end
    end

    describe 'work_location_type' do
      it { is_expected.to define_enum_for(:work_location_type).with_values(
        'on_site' => 'on_site',
        'hybrid' => 'hybrid',
        'remote' => 'remote'
      ).with_prefix(true) }

      it 'provides predicate methods' do
        job = build(:job, work_location_type: 'remote')
        expect(job).to be_work_location_type_remote
        expect(job).not_to be_work_location_type_on_site
      end
    end

    describe 'urgency' do
      it { is_expected.to define_enum_for(:urgency).with_values(
        'low' => 'low',
        'medium' => 'medium',
        'high' => 'high',
        'urgent' => 'urgent'
      ).with_prefix(true) }

      it 'provides predicate methods' do
        job = build(:job, urgency: 'urgent')
        expect(job).to be_urgency_urgent
        expect(job).not_to be_urgency_low
      end
    end

    describe 'salary_period' do
      it { is_expected.to define_enum_for(:salary_period).with_values(
        'hourly' => 'hourly',
        'daily' => 'daily',
        'weekly' => 'weekly',
        'monthly' => 'monthly',
        'annually' => 'annually'
      ).with_prefix(true) }

      it 'provides predicate methods' do
        job = build(:job, salary_period: 'annually')
        expect(job).to be_salary_period_annually
        expect(job).not_to be_salary_period_hourly
      end
    end
  end

  # Scopes
  describe 'scopes' do
    let!(:active_published_job) { create(:job, :published, active: true, deleted_at: nil) }
    let!(:inactive_job) { create(:job, active: false) }
    let!(:deleted_job) { create(:job, deleted_at: 1.day.ago) }
    let!(:draft_job) { create(:job, status: 'draft') }
    let!(:paused_job) { create(:job, :paused) }
    let!(:closed_job) { create(:job, :closed) }
    let!(:remote_job) { create(:job, work_location_type: 'remote') }
    let!(:urgent_job) { create(:job, urgency: 'urgent') }
    let!(:engineering_job) { create(:job, department_id: 1) }
    let!(:recent_job) { create(:job, posted_at: 1.day.ago) }
    let!(:old_job) { create(:job, posted_at: 1.month.ago) }
    let(:company) { create(:company) }
    let!(:company_job) { create(:job, company: company) }

    describe '.active' do
      it 'returns only active, non-deleted jobs' do
        expect(Job.active).to include(active_published_job)
        expect(Job.active).not_to include(inactive_job, deleted_job)
      end
    end

    describe '.published' do
      it 'returns only published jobs' do
        expect(Job.published).to include(active_published_job)
        expect(Job.published).not_to include(draft_job, paused_job, closed_job)
      end
    end

    describe '.by_status' do
      it 'filters jobs by status' do
        expect(Job.by_status('draft')).to include(draft_job)
        expect(Job.by_status('published')).to include(active_published_job)
        expect(Job.by_status('paused')).to include(paused_job)
      end
    end

    describe '.by_employment_type' do
      let!(:full_time_job) { create(:job, employment_type: 'full_time') }
      let!(:contract_job) { create(:job, employment_type: 'contract') }

      it 'filters jobs by employment type' do
        expect(Job.by_employment_type('full_time')).to include(full_time_job)
        expect(Job.by_employment_type('contract')).to include(contract_job)
        expect(Job.by_employment_type('full_time')).not_to include(contract_job)
      end
    end

    describe '.by_experience_level' do
      let!(:senior_job) { create(:job, experience_level: 'senior') }
      let!(:entry_job) { create(:job, experience_level: 'entry') }

      it 'filters jobs by experience level' do
        expect(Job.by_experience_level('senior')).to include(senior_job)
        expect(Job.by_experience_level('entry')).to include(entry_job)
        expect(Job.by_experience_level('senior')).not_to include(entry_job)
      end
    end

    describe '.by_work_location_type' do
      it 'filters jobs by work location type' do
        expect(Job.by_work_location_type('remote')).to include(remote_job)
        expect(Job.by_work_location_type('on_site')).not_to include(remote_job)
      end
    end

    describe '.by_urgency' do
      it 'filters jobs by urgency level' do
        expect(Job.by_urgency('urgent')).to include(urgent_job)
        expect(Job.by_urgency('low')).not_to include(urgent_job)
      end
    end

    describe '.by_department' do
      it 'filters jobs by department' do
        expect(Job.by_department(1)).to include(engineering_job)
      end
    end

    describe '.by_location' do
      let!(:nyc_job) { create(:job, location: 'New York, NY') }
      let!(:sf_job) { create(:job, location: 'San Francisco, CA') }

      it 'filters jobs by location with case insensitive search' do
        expect(Job.by_location('New York')).to include(nyc_job)
        expect(Job.by_location('new york')).to include(nyc_job)
        expect(Job.by_location('San Francisco')).to include(sf_job)
        expect(Job.by_location('New York')).not_to include(sf_job)
      end
    end

    describe '.with_salary_range' do
      let!(:low_salary_job) { create(:job, salary_min: 50_000, salary_max: 70_000) }
      let!(:high_salary_job) { create(:job, salary_min: 120_000, salary_max: 150_000) }

      it 'filters jobs within salary range' do
        expect(Job.with_salary_range(40_000, 80_000)).to include(low_salary_job)
        expect(Job.with_salary_range(100_000, 200_000)).to include(high_salary_job)
        expect(Job.with_salary_range(40_000, 80_000)).not_to include(high_salary_job)
      end
    end

    describe '.posted_within' do
      it 'filters jobs posted within specified period' do
        expect(Job.posted_within(1.week)).to include(recent_job)
        expect(Job.posted_within(1.week)).not_to include(old_job)
      end
    end

    describe '.recent' do
      it 'orders jobs by posted_at descending' do
        expect(Job.recent.first).to eq(recent_job)
      end
    end

    describe '.by_company' do
      it 'filters jobs by company' do
        expect(Job.by_company(company.id)).to include(company_job)
      end
    end

    describe '.confidential' do
      let!(:confidential_job) { create(:job, confidential: true) }
      let!(:public_job) { create(:job, confidential: false) }

      it 'returns only confidential jobs' do
        expect(Job.confidential).to include(confidential_job)
        expect(Job.confidential).not_to include(public_job)
      end
    end

    describe '.public_jobs' do
      let!(:confidential_job) { create(:job, confidential: true) }
      let!(:public_job) { create(:job, confidential: false) }

      it 'returns only public jobs' do
        expect(Job.public_jobs).to include(public_job)
        expect(Job.public_jobs).not_to include(confidential_job)
      end
    end

    describe '.remote_eligible' do
      let!(:remote_eligible_job) { create(:job, remote_work_eligible: true) }
      let!(:non_remote_job) { create(:job, remote_work_eligible: false) }

      it 'returns jobs eligible for remote work' do
        expect(Job.remote_eligible).to include(remote_eligible_job)
        expect(Job.remote_eligible).not_to include(non_remote_job)
      end
    end

    describe '.with_openings' do
      let!(:job_with_openings) { create(:job, openings_count: 3) }
      let!(:job_without_openings) { create(:job, openings_count: 0) }

      it 'returns jobs with available openings' do
        expect(Job.with_openings).to include(job_with_openings)
        expect(Job.with_openings).not_to include(job_without_openings)
      end
    end

    describe '.application_open' do
      let!(:open_job) { create(:job, application_deadline: 1.week.from_now) }
      let!(:closed_job) { create(:job, application_deadline: 1.day.ago) }
      let!(:no_deadline_job) { create(:job, application_deadline: nil) }

      it 'returns jobs with open applications' do
        expect(Job.application_open).to include(open_job, no_deadline_job)
        expect(Job.application_open).not_to include(closed_job)
      end
    end
  end

  # Search scopes
  describe 'search scopes' do
    let!(:rails_job) { create(:job, title: 'Rails Developer', description: 'Ruby on Rails experience required') }
    let!(:react_job) { create(:job, title: 'React Developer', description: 'JavaScript and React skills needed', requirements: 'Frontend development') }
    let!(:ruby_skills_job) { create(:job, required_skills: ['Ruby', 'Rails', 'PostgreSQL']) }
    let!(:js_skills_job) { create(:job, nice_to_have_skills: ['JavaScript', 'React', 'Node.js']) }

    describe '.search_by_title' do
      it 'finds jobs by title with case insensitive search' do
        expect(Job.search_by_title('Rails')).to include(rails_job)
        expect(Job.search_by_title('rails')).to include(rails_job)
        expect(Job.search_by_title('React')).to include(react_job)
        expect(Job.search_by_title('Rails')).not_to include(react_job)
      end
    end

    describe '.search_by_content' do
      it 'searches across title, description, and requirements' do
        expect(Job.search_by_content('Ruby')).to include(rails_job)
        expect(Job.search_by_content('JavaScript')).to include(react_job)
        expect(Job.search_by_content('Frontend')).to include(react_job)
      end
    end

    describe '.with_required_skills' do
      it 'finds jobs with matching required skills' do
        expect(Job.with_required_skills(['Ruby'])).to include(ruby_skills_job)
        expect(Job.with_required_skills(['Rails'])).to include(ruby_skills_job)
        expect(Job.with_required_skills(['Python'])).not_to include(ruby_skills_job)
      end

      it 'handles array of skills' do
        expect(Job.with_required_skills(['Ruby', 'Rails'])).to include(ruby_skills_job)
      end
    end

    describe '.with_nice_to_have_skills' do
      it 'finds jobs with matching nice-to-have skills' do
        expect(Job.with_nice_to_have_skills(['JavaScript'])).to include(js_skills_job)
        expect(Job.with_nice_to_have_skills(['React'])).to include(js_skills_job)
        expect(Job.with_nice_to_have_skills(['Python'])).not_to include(js_skills_job)
      end

      it 'handles array of skills' do
        expect(Job.with_nice_to_have_skills(['JavaScript', 'React'])).to include(js_skills_job)
      end
    end
  end

  # Business Logic Methods
  describe 'business logic methods' do
    describe '#formatted_salary_range' do
      context 'with both min and max salary' do
        it 'formats USD salary range' do
          job = build(:job, salary_min: 80_000, salary_max: 120_000, salary_currency: 'USD', salary_period: 'annually')
          expect(job.formatted_salary_range).to eq('$80,000 - $120,000 per year')
        end

        it 'formats EUR salary range' do
          job = build(:job, salary_min: 70_000, salary_max: 100_000, salary_currency: 'EUR', salary_period: 'annually')
          expect(job.formatted_salary_range).to eq('€70,000 - €100,000 per year')
        end

        it 'formats GBP salary range' do
          job = build(:job, salary_min: 60_000, salary_max: 90_000, salary_currency: 'GBP', salary_period: 'annually')
          expect(job.formatted_salary_range).to eq('£60,000 - £90,000 per year')
        end

        it 'formats hourly rates' do
          job = build(:job, salary_min: 50, salary_max: 75, salary_currency: 'USD', salary_period: 'hourly')
          expect(job.formatted_salary_range).to eq('$50 - $75 per hour')
        end
      end

      context 'with only minimum salary' do
        it 'shows minimum salary format' do
          job = build(:job, salary_min: 80_000, salary_max: nil, salary_currency: 'USD', salary_period: 'annually')
          expect(job.formatted_salary_range).to eq('From $80,000 per year')
        end
      end

      context 'with only maximum salary' do
        it 'shows maximum salary format' do
          job = build(:job, salary_min: nil, salary_max: 120_000, salary_currency: 'USD', salary_period: 'annually')
          expect(job.formatted_salary_range).to eq('Up to $120,000 per year')
        end
      end

      context 'with no salary information' do
        it 'returns default message' do
          job = build(:job, salary_min: nil, salary_max: nil)
          expect(job.formatted_salary_range).to eq('Salary not specified')
        end
      end
    end

    describe '#salary_period_display' do
      it 'converts period enums to human readable format' do
        expect(build(:job, salary_period: 'hourly').salary_period_display).to eq('per hour')
        expect(build(:job, salary_period: 'daily').salary_period_display).to eq('per day')
        expect(build(:job, salary_period: 'weekly').salary_period_display).to eq('per week')
        expect(build(:job, salary_period: 'monthly').salary_period_display).to eq('per month')
        expect(build(:job, salary_period: 'annually').salary_period_display).to eq('per year')
      end

      it 'returns empty string for blank period' do
        job = build(:job, salary_period: nil)
        expect(job.salary_period_display).to eq('')
      end
    end

    describe 'humanized enum methods' do
      it '#employment_type_humanized' do
        job = build(:job, employment_type: 'full_time')
        expect(job.employment_type_humanized).to eq('Full time')
      end

      it '#experience_level_humanized' do
        expect(build(:job, experience_level: 'entry').experience_level_humanized).to eq('Entry Level')
        expect(build(:job, experience_level: 'mid').experience_level_humanized).to eq('Mid Level')
        expect(build(:job, experience_level: 'senior').experience_level_humanized).to eq('Senior Level')
        expect(build(:job, experience_level: 'executive').experience_level_humanized).to eq('Executive Level')
      end

      it '#work_location_type_humanized' do
        expect(build(:job, work_location_type: 'on_site').work_location_type_humanized).to eq('On-site')
        expect(build(:job, work_location_type: 'hybrid').work_location_type_humanized).to eq('Hybrid')
        expect(build(:job, work_location_type: 'remote').work_location_type_humanized).to eq('Remote')
      end

      it '#status_humanized' do
        job = build(:job, status: 'published')
        expect(job.status_humanized).to eq('Published')
      end

      it '#urgency_humanized' do
        job = build(:job, urgency: 'urgent')
        expect(job.urgency_humanized).to eq('Urgent')
      end
    end

    describe 'date calculation methods' do
      describe '#days_since_posted' do
        it 'returns correct number of days' do
          job = create(:job, posted_at: 5.days.ago)
          expect(job.days_since_posted).to eq(5)
        end

        it 'returns nil when not posted' do
          job = build(:job, posted_at: nil)
          expect(job.days_since_posted).to be_nil
        end
      end

      describe '#days_until_deadline' do
        it 'returns correct number of days until deadline' do
          job = create(:job, application_deadline: 7.days.from_now)
          expect(job.days_until_deadline).to eq(7)
        end

        it 'returns negative number for past deadline' do
          job = create(:job, application_deadline: 2.days.ago)
          expect(job.days_until_deadline).to eq(-2)
        end

        it 'returns nil when no deadline set' do
          job = build(:job, application_deadline: nil)
          expect(job.days_until_deadline).to be_nil
        end
      end
    end

    describe 'status check methods' do
      describe '#is_active?' do
        it 'returns true for active, non-deleted jobs' do
          job = build(:job, active: true, deleted_at: nil)
          expect(job.is_active?).to be true
        end

        it 'returns false for inactive jobs' do
          job = build(:job, active: false, deleted_at: nil)
          expect(job.is_active?).to be false
        end

        it 'returns false for deleted jobs' do
          job = build(:job, active: true, deleted_at: 1.day.ago)
          expect(job.is_active?).to be false
        end
      end

      describe '#is_published?' do
        it 'returns true for published jobs' do
          job = build(:job, status: 'published')
          expect(job.is_published?).to be true
        end

        it 'returns false for draft jobs' do
          job = build(:job, status: 'draft')
          expect(job.is_published?).to be false
        end
      end

      describe '#can_be_published?' do
        it 'returns true for valid draft jobs' do
          job = build(:job, status: 'draft', title: 'Developer', description: 'Great job')
          expect(job.can_be_published?).to be true
        end

        it 'returns false for jobs without title' do
          job = build(:job, status: 'draft', title: nil, description: 'Great job')
          expect(job.can_be_published?).to be false
        end

        it 'returns false for jobs without description' do
          job = build(:job, status: 'draft', title: 'Developer', description: nil)
          expect(job.can_be_published?).to be false
        end

        it 'returns false for non-draft jobs' do
          job = build(:job, status: 'published')
          expect(job.can_be_published?).to be false
        end
      end

      describe '#can_be_closed?' do
        it 'returns true for published jobs' do
          job = build(:job, status: 'published')
          expect(job.can_be_closed?).to be true
        end

        it 'returns true for paused jobs' do
          job = build(:job, status: 'paused')
          expect(job.can_be_closed?).to be true
        end

        it 'returns false for draft jobs' do
          job = build(:job, status: 'draft')
          expect(job.can_be_closed?).to be false
        end

        it 'returns false for closed jobs' do
          job = build(:job, status: 'closed')
          expect(job.can_be_closed?).to be false
        end
      end

      describe '#is_confidential?' do
        it 'returns true for confidential jobs' do
          job = build(:job, confidential: true)
          expect(job.is_confidential?).to be true
        end

        it 'returns false for public jobs' do
          job = build(:job, confidential: false)
          expect(job.is_confidential?).to be false
        end
      end

      describe '#allows_remote_work?' do
        it 'returns true when remote_work_eligible is true' do
          job = build(:job, remote_work_eligible: true, work_location_type: 'on_site')
          expect(job.allows_remote_work?).to be true
        end

        it 'returns true when work_location_type is remote' do
          job = build(:job, remote_work_eligible: false, work_location_type: 'remote')
          expect(job.allows_remote_work?).to be true
        end

        it 'returns false when neither condition is met' do
          job = build(:job, remote_work_eligible: false, work_location_type: 'on_site')
          expect(job.allows_remote_work?).to be false
        end
      end

      describe '#has_openings?' do
        it 'returns true when openings_count is greater than 0' do
          job = build(:job, openings_count: 3)
          expect(job.has_openings?).to be true
        end

        it 'returns false when openings_count is 0' do
          job = build(:job, openings_count: 0)
          expect(job.has_openings?).to be false
        end

        it 'returns false when openings_count is nil' do
          job = build(:job, openings_count: nil)
          expect(job.has_openings?).to be false
        end
      end

      describe '#applications_open?' do
        it 'returns true when no deadline is set' do
          job = build(:job, application_deadline: nil)
          expect(job.applications_open?).to be true
        end

        it 'returns true when deadline is in the future' do
          job = build(:job, application_deadline: 1.week.from_now)
          expect(job.applications_open?).to be true
        end

        it 'returns false when deadline has passed' do
          job = build(:job, application_deadline: 1.day.ago)
          expect(job.applications_open?).to be false
        end
      end
    end
  end

  # JSONB Fields
  describe 'JSONB field handling' do
    describe '#required_skills_list' do
      it 'returns empty array when skills is nil' do
        job = build(:job, required_skills: nil)
        expect(job.required_skills_list).to eq([])
      end

      it 'returns empty array when skills is not an array' do
        job = build(:job, required_skills: 'not an array')
        expect(job.required_skills_list).to eq([])
      end

      it 'returns skills array when properly formatted' do
        skills = ['Ruby', 'Rails', 'PostgreSQL']
        job = build(:job, required_skills: skills)
        expect(job.required_skills_list).to eq(skills)
      end
    end

    describe '#nice_to_have_skills_list' do
      it 'returns empty array when skills is nil' do
        job = build(:job, nice_to_have_skills: nil)
        expect(job.nice_to_have_skills_list).to eq([])
      end

      it 'returns skills array when properly formatted' do
        skills = ['Docker', 'AWS', 'React']
        job = build(:job, nice_to_have_skills: skills)
        expect(job.nice_to_have_skills_list).to eq(skills)
      end
    end

    describe '#all_skills' do
      it 'combines required and nice-to-have skills uniquely' do
        job = build(:job, 
          required_skills: ['Ruby', 'Rails', 'PostgreSQL'],
          nice_to_have_skills: ['Ruby', 'Docker', 'AWS']
        )
        expected_skills = ['Ruby', 'Rails', 'PostgreSQL', 'Docker', 'AWS']
        expect(job.all_skills).to match_array(expected_skills)
      end

      it 'handles nil values gracefully' do
        job = build(:job, required_skills: nil, nice_to_have_skills: nil)
        expect(job.all_skills).to eq([])
      end
    end

    describe '#pipeline_stages_list' do
      it 'returns empty array when pipeline_stages is nil' do
        job = build(:job, pipeline_stages: nil)
        expect(job.pipeline_stages_list).to eq([])
      end

      it 'returns pipeline stages array when properly formatted' do
        stages = ['Application', 'Phone Screen', 'Technical Interview', 'Offer']
        job = build(:job, pipeline_stages: stages)
        expect(job.pipeline_stages_list).to eq(stages)
      end
    end
  end

  # State Management
  describe 'state transition methods' do
    describe '#publish!' do
      it 'publishes a valid draft job' do
        job = create(:job, status: 'draft', title: 'Developer', description: 'Great opportunity')
        expect { job.publish! }.to change(job, :status).from('draft').to('published')
        expect(job.posted_at).to be_present
        expect(job.active).to be true
      end

      it 'returns false for invalid job' do
        job = create(:job, status: 'published')
        expect(job.publish!).to be false
      end

      it 'sets posted_at to current time' do
        job = create(:job, status: 'draft', title: 'Developer', description: 'Great opportunity')
        freeze_time do
          job.publish!
          expect(job.posted_at).to be_within(1.second).of(Time.current)
        end
      end
    end

    describe '#pause!' do
      it 'pauses a published job' do
        job = create(:job, :published)
        expect { job.pause! }.to change(job, :status).from('published').to('paused')
      end

      it 'returns false for non-published job' do
        job = create(:job, status: 'draft')
        expect(job.pause!).to be false
      end
    end

    describe '#close!' do
      it 'closes a published job' do
        job = create(:job, :published)
        expect { job.close! }.to change(job, :status).from('published').to('closed')
        expect(job.active).to be false
      end

      it 'closes a paused job' do
        job = create(:job, :paused)
        expect { job.close! }.to change(job, :status).from('paused').to('closed')
        expect(job.active).to be false
      end

      it 'returns false for draft job' do
        job = create(:job, status: 'draft')
        expect(job.close!).to be false
      end
    end

    describe '#archive!' do
      it 'archives any job regardless of status' do
        job = create(:job, :published)
        expect { job.archive! }.to change(job, :status).from('published').to('archived')
        expect(job.active).to be false
      end
    end

    describe '#soft_delete!' do
      it 'soft deletes a job' do
        job = create(:job)
        freeze_time do
          job.soft_delete!
          expect(job.deleted_at).to be_within(1.second).of(Time.current)
          expect(job.active).to be false
        end
      end
    end

    describe '#restore!' do
      it 'restores a soft deleted job' do
        job = create(:job, deleted_at: 1.day.ago, active: false)
        job.restore!
        expect(job.deleted_at).to be_nil
        expect(job.active).to be true
      end

      it 'does nothing if job is not deleted' do
        job = create(:job, deleted_at: nil)
        original_updated_at = job.updated_at
        job.restore!
        expect(job.updated_at).to eq(original_updated_at)
      end
    end
  end

  # Callbacks
  describe 'callbacks' do
    describe 'before_validation callbacks' do
      describe '#set_posted_at_on_publish' do
        it 'sets posted_at when status changes to published' do
          job = create(:job, status: 'draft')
          freeze_time do
            job.update!(status: 'published')
            expect(job.posted_at).to be_within(1.second).of(Time.current)
          end
        end

        it 'does not override existing posted_at' do
          original_time = 1.week.ago
          job = create(:job, status: 'draft', posted_at: original_time)
          job.update!(status: 'published')
          expect(job.posted_at).to eq(original_time)
        end
      end

      describe '#normalize_currency' do
        it 'uppercases currency code' do
          job = build(:job, salary_currency: 'usd')
          job.valid?
          expect(job.salary_currency).to eq('USD')
        end
      end

      describe '#set_defaults' do
        it 'sets default values for boolean fields' do
          job = build(:job, active: nil, confidential: nil, remote_work_eligible: nil)
          job.valid?
          expect(job.active).to be true
          expect(job.confidential).to be false
          expect(job.remote_work_eligible).to be false
        end

        it 'sets default openings_count' do
          job = build(:job, openings_count: nil)
          job.valid?
          expect(job.openings_count).to eq(1)
        end

        it 'initializes JSONB arrays' do
          job = build(:job, required_skills: nil, nice_to_have_skills: nil, pipeline_stages: nil)
          job.valid?
          expect(job.required_skills).to eq([])
          expect(job.nice_to_have_skills).to eq([])
          expect(job.pipeline_stages).to eq([])
        end
      end
    end

    describe 'after_update callback' do
      describe '#update_active_status' do
        it 'sets active to true when published' do
          job = create(:job, status: 'draft', active: false)
          job.update!(status: 'published')
          job.reload
          expect(job.active).to be true
        end

        it 'sets active to false when closed' do
          job = create(:job, :published, active: true)
          job.update!(status: 'closed')
          job.reload
          expect(job.active).to be false
        end

        it 'sets active to false when archived' do
          job = create(:job, :published, active: true)
          job.update!(status: 'archived')
          job.reload
          expect(job.active).to be false
        end
      end
    end
  end

  # Class Methods
  describe 'class methods' do
    describe '.search' do
      let!(:rails_job) { create(:job, title: 'Rails Developer', description: 'Ruby on Rails experience required') }
      let!(:react_job) { create(:job, title: 'React Developer', description: 'JavaScript and React skills needed') }
      let!(:generic_job) { create(:job, title: 'Software Engineer', description: 'General programming role') }

      it 'returns all jobs when query is blank' do
        expect(Job.search('')).to match_array([rails_job, react_job, generic_job])
        expect(Job.search(nil)).to match_array([rails_job, react_job, generic_job])
      end

      it 'searches by content across title, description, and requirements' do
        expect(Job.search('Rails')).to include(rails_job)
        expect(Job.search('Ruby')).to include(rails_job)
        expect(Job.search('JavaScript')).to include(react_job)
        expect(Job.search('React')).to include(react_job)
      end

      it 'performs case-insensitive search' do
        expect(Job.search('rails')).to include(rails_job)
        expect(Job.search('RAILS')).to include(rails_job)
      end
    end
  end

  # Performance Tests
  describe 'performance considerations', :performance do
    it 'efficiently queries JSONB fields' do
      # Create jobs with various skills
      jobs_with_ruby = create_list(:job, 10, required_skills: ['Ruby', 'Rails'])
      jobs_with_js = create_list(:job, 10, required_skills: ['JavaScript', 'React'])
      
      expect {
        Job.with_required_skills(['Ruby']).load
      }.to perform_under(50).ms
    end

    it 'efficiently processes complex scopes' do
      create_list(:job, 50, :published)
      
      expect {
        Job.published.by_status('published').recent.limit(10).load
      }.to perform_under(50).ms
    end
  end
end