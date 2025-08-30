# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Application, type: :model do
  # Factory setup
  let(:company) { create(:company) }
  let(:candidate) { create(:candidate) }
  let(:job) { create(:job, company: company) }
  let(:user) { create(:user, company: company) }
  
  describe 'associations' do
    it { should belong_to(:company) }
    it { should belong_to(:job) }
    it { should belong_to(:candidate) }
    it { should belong_to(:stage_changed_by).class_name('User').optional }
    it { should have_many(:interviews).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:application, company: company, job: job, candidate: candidate) }

    context 'presence validations' do
      it { should validate_presence_of(:company_id) }
      it { should validate_presence_of(:job_id) }
      it { should validate_presence_of(:candidate_id) }
      it { should validate_presence_of(:status) }
      it { should validate_presence_of(:applied_at) }
      it { should validate_presence_of(:metadata) }
    end

    context 'uniqueness validations' do
      before { create(:application, company: company, job: job, candidate: candidate) }
      
      it 'validates uniqueness of candidate_id scoped to job_id' do
        duplicate_application = build(:application, company: company, job: job, candidate: candidate)
        expect(duplicate_application).not_to be_valid
        expect(duplicate_application.errors[:candidate_id]).to include('has already applied to this job')
      end

      it 'allows same candidate to apply to different jobs' do
        different_job = create(:job, company: company)
        new_application = build(:application, company: company, job: different_job, candidate: candidate)
        expect(new_application).to be_valid
      end

      it 'allows different candidates to apply to same job' do
        different_candidate = create(:candidate)
        new_application = build(:application, company: company, job: job, candidate: different_candidate)
        expect(new_application).to be_valid
      end
    end

    context 'rating validation' do
      it { should allow_value(nil).for(:rating) }
      it { should allow_value(1).for(:rating) }
      it { should allow_value(3).for(:rating) }
      it { should allow_value(5).for(:rating) }
      it { should_not allow_value(0).for(:rating) }
      it { should_not allow_value(6).for(:rating) }
      it { should_not allow_value(-1).for(:rating) }
      it { should_not allow_value('string').for(:rating) }

      it 'has proper error message for invalid rating' do
        application = build(:application, rating: 6)
        application.valid?
        expect(application.errors[:rating]).to include('must be between 1 and 5')
      end
    end

    context 'salary validation' do
      it { should allow_value(nil).for(:salary_offered) }
      it { should allow_value(0).for(:salary_offered) }
      it { should allow_value(100000).for(:salary_offered) }
      it { should_not allow_value(-1).for(:salary_offered) }
      it { should_not allow_value(-100000).for(:salary_offered) }

      it 'has proper error message for negative salary' do
        application = build(:application, salary_offered: -5000)
        application.valid?
        expect(application.errors[:salary_offered]).to include('must be a positive amount')
      end
    end

    context 'source validation' do
      Application::APPLICATION_SOURCES.each do |source|
        it { should allow_value(source).for(:source) }
      end
      
      it { should allow_value(nil).for(:source) }
      it { should allow_value('').for(:source) }
      it { should_not allow_value('invalid_source').for(:source) }

      it 'has proper error message for invalid source' do
        application = build(:application, source: 'invalid_source')
        application.valid?
        expect(application.errors[:source]).to include('is not a valid application source')
      end
    end

    context 'string length validations' do
      it { should validate_length_of(:rejection_reason).is_at_most(255) }
      it { should validate_length_of(:source).is_at_most(100) }
      it { should validate_length_of(:cover_letter).is_at_most(5000) }
      it { should validate_length_of(:notes).is_at_most(2000) }
    end

    context 'custom validations' do
      describe 'rejection_data_consistency' do
        it 'requires rejected_at when status is rejected' do
          application = build(:application, status: 'rejected', rejected_at: nil)
          expect(application).not_to be_valid
          expect(application.errors[:rejected_at]).to include('must be present when status is rejected')
        end

        it 'requires rejected_at to be blank when status is not rejected' do
          application = build(:application, status: 'applied', rejected_at: Time.current)
          expect(application).not_to be_valid
          expect(application.errors[:rejected_at]).to include('must be blank when status is not rejected')
        end

        it 'allows rejected_at when status is rejected' do
          application = build(:application, status: 'rejected', rejected_at: Time.current)
          expect(application).to be_valid
        end
      end

      describe 'stage_changed_by_belongs_to_company' do
        it 'requires stage_changed_by to belong to same company' do
          other_company = create(:company)
          other_user = create(:user, company: other_company)
          application = build(:application, company: company, stage_changed_by: other_user)
          
          expect(application).not_to be_valid
          expect(application.errors[:stage_changed_by]).to include('must belong to the same company')
        end

        it 'allows stage_changed_by from same company' do
          application = build(:application, company: company, stage_changed_by: user)
          expect(application).to be_valid
        end

        it 'allows nil stage_changed_by' do
          application = build(:application, company: company, stage_changed_by: nil)
          expect(application).to be_valid
        end
      end

      describe 'applied_at_not_in_future' do
        it 'does not allow applied_at in the future' do
          application = build(:application, applied_at: 1.day.from_now)
          expect(application).not_to be_valid
          expect(application.errors[:applied_at]).to include('cannot be in the future')
        end

        it 'allows applied_at in the past' do
          application = build(:application, applied_at: 1.day.ago)
          expect(application).to be_valid
        end

        it 'allows applied_at as current time' do
          freeze_time do
            application = build(:application, applied_at: Time.current)
            expect(application).to be_valid
          end
        end
      end
    end
  end

  describe 'enums' do
    describe 'status' do
      let(:statuses) do
        %w[applied screening phone_interview technical_interview final_interview offer accepted rejected withdrawn]
      end

      it 'defines all expected statuses' do
        expect(Application.statuses.keys).to match_array(statuses)
      end

      it 'defines predicate methods for all statuses' do
        statuses.each do |status|
          application_attrs = { status: status }
          # Some statuses require additional fields
          application_attrs[:rejected_at] = Time.current if status == 'rejected'
          
          application = create(:application, application_attrs)
          expect(application.send("status_#{status}?")).to be true
        end
      end

      it 'prefixes enum methods correctly' do
        application = create(:application, status: 'applied')
        expect(application.status_applied?).to be true
        expect(application.status_rejected?).to be false
      end
    end
  end

  describe 'callbacks' do
    describe 'before_validation callbacks' do
      it 'sets applied_at on create if not present' do
        freeze_time do
          application = build(:application, applied_at: nil)
          application.valid?
          expect(application.applied_at).to eq(Time.current)
        end
      end

      it 'does not override existing applied_at on create' do
        existing_time = 2.days.ago
        application = build(:application, applied_at: existing_time)
        application.valid?
        expect(application.applied_at).to eq(existing_time)
      end

      it 'sets stage_changed_at when status changes' do
        application = create(:application, status: 'applied')
        
        freeze_time do
          application.status = 'screening'
          application.valid?
          expect(application.stage_changed_at).to eq(Time.current)
        end
      end

      it 'does not set stage_changed_at when status does not change' do
        application = create(:application, status: 'applied', stage_changed_at: nil)
        application.notes = 'Updated notes'
        application.valid?
        expect(application.stage_changed_at).to be_nil
      end
    end

    describe 'after_update callbacks' do
      it 'updates rejection timestamp when status changes to rejected' do
        application = create(:application, status: 'applied')
        
        freeze_time do
          application.update!(status: 'rejected')
          expect(application.reload.rejected_at).to eq(Time.current)
        end
      end

      it 'clears rejection timestamp when status changes from rejected' do
        application = create(:application, status: 'rejected', rejected_at: 1.day.ago)
        application.update!(status: 'applied')
        expect(application.reload.rejected_at).to be_nil
      end
    end
  end

  describe 'scopes' do
    let!(:company1) { create(:company) }
    let!(:company2) { create(:company) }
    let!(:job1) { create(:job, company: company1) }
    let!(:job2) { create(:job, company: company2) }
    let!(:candidate1) { create(:candidate) }
    let!(:candidate2) { create(:candidate) }

    before do
      # Create applications with various statuses and attributes
      @app1 = create(:application, company: company1, job: job1, candidate: candidate1, 
                     status: 'applied', source: 'linkedin', rating: 4, applied_at: 3.days.ago)
      @app2 = create(:application, company: company1, job: job1, candidate: candidate2, 
                     status: 'screening', source: 'indeed', rating: nil, applied_at: 2.days.ago)
      @app3 = create(:application, company: company2, job: job2, candidate: candidate1, 
                     status: 'rejected', source: 'linkedin', rating: 2, applied_at: 1.day.ago)
      @app4 = create(:application, company: company1, job: job1, candidate: create(:candidate), 
                     status: 'accepted', source: 'referral', rating: 5, applied_at: 5.days.ago)
    end

    describe 'basic scopes' do
      it 'filters by company' do
        expect(Application.for_company(company1)).to contain_exactly(@app1, @app2, @app4)
      end

      it 'filters by job' do
        expect(Application.for_job(job1)).to contain_exactly(@app1, @app2, @app4)
      end

      it 'filters by candidate' do
        expect(Application.for_candidate(candidate1)).to contain_exactly(@app1, @app3)
      end

      it 'filters by status' do
        expect(Application.by_status('applied')).to contain_exactly(@app1)
      end

      it 'filters by source' do
        expect(Application.by_source('linkedin')).to contain_exactly(@app1, @app3)
      end

      it 'filters by rating' do
        expect(Application.with_rating(4)).to contain_exactly(@app1)
      end
    end

    describe 'rating-based scopes' do
      it 'finds rated applications' do
        expect(Application.rated_applications).to contain_exactly(@app1, @app3, @app4)
      end

      it 'finds unrated applications' do
        expect(Application.unrated_applications).to contain_exactly(@app2)
      end

      it 'finds highly rated applications' do
        expect(Application.highly_rated).to contain_exactly(@app1, @app4)
      end

      it 'finds poorly rated applications' do
        expect(Application.poorly_rated).to contain_exactly(@app3)
      end
    end

    describe 'timeline scopes' do
      it 'filters applications between dates' do
        result = Application.applied_between(4.days.ago, 1.day.ago)
        expect(result).to contain_exactly(@app1, @app2, @app3)
      end

      it 'filters applications since date' do
        result = Application.applied_since(2.days.ago)
        expect(result).to contain_exactly(@app2, @app3)
      end

      it 'orders by recent applications' do
        expect(Application.recent.to_a).to eq([@app3, @app2, @app1, @app4])
      end

      it 'orders by oldest first' do
        expect(Application.oldest_first.to_a).to eq([@app4, @app1, @app2, @app3])
      end
    end

    describe 'status-based scopes' do
      it 'finds active applications' do
        expect(Application.active).to contain_exactly(@app1, @app2)
      end

      it 'finds closed applications' do
        expect(Application.closed).to contain_exactly(@app3, @app4)
      end

      it 'finds applications in pipeline' do
        screening_app = create(:application, status: 'screening')
        phone_app = create(:application, status: 'phone_interview')
        expect(Application.in_pipeline).to include(screening_app, phone_app, @app2)
      end

      it 'finds applications needing action' do
        expect(Application.needs_action).to contain_exactly(@app1, @app2)
      end

      it 'finds applications in interview stage' do
        phone_app = create(:application, status: 'phone_interview')
        tech_app = create(:application, status: 'technical_interview')
        final_app = create(:application, status: 'final_interview')
        expect(Application.interview_stage).to contain_exactly(phone_app, tech_app, final_app)
      end

      it 'finds applications in offer stage' do
        offer_app = create(:application, status: 'offer')
        expect(Application.offer_stage).to contain_exactly(offer_app, @app4)
      end
    end

    describe 'additional filtering scopes' do
      before do
        @app_with_offer = create(:application, salary_offered: 75000)
        @app_with_notes = create(:application, notes: 'Great candidate')
        @app_with_cover_letter = create(:application, cover_letter: 'I am interested in this position')
      end

      it 'finds applications with offers' do
        expect(Application.with_offer).to include(@app_with_offer)
      end

      it 'finds applications with notes' do
        expect(Application.with_notes).to include(@app_with_notes)
      end

      it 'finds applications with cover letters' do
        expect(Application.with_cover_letter).to include(@app_with_cover_letter)
      end
    end

    describe 'search scopes' do
      before do
        @app_with_rejection_reason = create(:application, status: 'rejected', 
                                            rejection_reason: 'not qualified for senior role')
        @app_with_searchable_notes = create(:application, notes: 'excellent communication skills',
                                            cover_letter: 'passionate about ruby development')
      end

      it 'searches by rejection reason' do
        result = Application.search_by_rejection_reason('qualified')
        expect(result).to include(@app_with_rejection_reason)
      end

      it 'searches in notes and cover letters' do
        result = Application.search_in_notes('communication')
        expect(result).to include(@app_with_searchable_notes)
        
        result = Application.search_in_notes('ruby')
        expect(result).to include(@app_with_searchable_notes)
      end
    end
  end

  describe 'delegations' do
    let(:application) { create(:application) }

    it 'delegates candidate methods with prefix' do
      expect(application.candidate_full_name).to eq(application.candidate.full_name)
      expect(application.candidate_email).to eq(application.candidate.email)
      expect(application.candidate_phone).to eq(application.candidate.phone)
    end

    it 'delegates job methods with prefix' do
      expect(application.job_title).to eq(application.job.title)
      expect(application.job_employment_type).to eq(application.job.employment_type)
    end

    it 'delegates company name with prefix' do
      expect(application.company_name).to eq(application.company.name)
    end

    it 'delegates stage_changed_by full_name with prefix and allows nil' do
      application_with_user = create(:application, stage_changed_by: user)
      application_without_user = create(:application, stage_changed_by: nil)
      
      expect(application_with_user.stage_changed_by_full_name).to eq(user.full_name)
      expect(application_without_user.stage_changed_by_full_name).to be_nil
    end
  end

  describe 'state transition methods' do
    let(:application) { create(:application, status: 'applied', company: company) }
    let(:changed_by) { create(:user, company: company) }

    describe '#advance_to_screening!' do
      it 'transitions to screening status' do
        freeze_time do
          application.advance_to_screening!(changed_by: changed_by, notes: 'Looks promising')
          
          expect(application.status).to eq('screening')
          expect(application.stage_changed_by).to eq(changed_by)
          expect(application.stage_changed_at).to eq(Time.current)
          expect(application.notes).to include('Looks promising')
        end
      end

      it 'works without optional parameters' do
        application.advance_to_screening!
        expect(application.status).to eq('screening')
      end
    end

    describe '#advance_to_phone_interview!' do
      it 'transitions to phone_interview status' do
        application.advance_to_phone_interview!(changed_by: changed_by)
        expect(application.status).to eq('phone_interview')
        expect(application.stage_changed_by).to eq(changed_by)
      end
    end

    describe '#advance_to_technical_interview!' do
      it 'transitions to technical_interview status' do
        application.advance_to_technical_interview!(changed_by: changed_by)
        expect(application.status).to eq('technical_interview')
        expect(application.stage_changed_by).to eq(changed_by)
      end
    end

    describe '#advance_to_final_interview!' do
      it 'transitions to final_interview status' do
        application.advance_to_final_interview!(changed_by: changed_by)
        expect(application.status).to eq('final_interview')
        expect(application.stage_changed_by).to eq(changed_by)
      end
    end

    describe '#extend_offer!' do
      it 'transitions to offer status with salary' do
        freeze_time do
          application.extend_offer!(salary_amount: 85000, changed_by: changed_by, notes: 'Great fit')
          
          expect(application.status).to eq('offer')
          expect(application.salary_offered).to eq(85000)
          expect(application.stage_changed_by).to eq(changed_by)
          expect(application.stage_changed_at).to eq(Time.current)
          expect(application.notes).to include('Great fit')
        end
      end

      it 'works without salary amount' do
        application.extend_offer!(changed_by: changed_by)
        expect(application.status).to eq('offer')
        expect(application.salary_offered).to be_nil
      end

      it 'appends notes to existing notes' do
        application.update!(notes: 'Initial notes')
        application.extend_offer!(notes: 'Offer extended')
        expect(application.notes).to include('Initial notes')
        expect(application.notes).to include('Offer extended')
      end
    end

    describe '#accept_offer!' do
      it 'transitions to accepted status' do
        application.accept_offer!(changed_by: changed_by)
        expect(application.status).to eq('accepted')
        expect(application.stage_changed_by).to eq(changed_by)
      end
    end

    describe '#reject!' do
      it 'transitions to rejected status with reason and timestamp' do
        freeze_time do
          application.reject!(reason: 'not qualified', changed_by: changed_by, notes: 'Lacks experience')
          
          expect(application.status).to eq('rejected')
          expect(application.rejected_at).to eq(Time.current)
          expect(application.rejection_reason).to eq('not qualified')
          expect(application.stage_changed_by).to eq(changed_by)
          expect(application.stage_changed_at).to eq(Time.current)
          expect(application.notes).to include('Lacks experience')
        end
      end

      it 'works without optional parameters' do
        application.reject!
        expect(application.status).to eq('rejected')
        expect(application.rejected_at).to be_present
      end
    end

    describe '#withdraw!' do
      it 'transitions to withdrawn status' do
        freeze_time do
          application.withdraw!(reason: 'accepted other offer', changed_by: changed_by, notes: 'Candidate withdrew')
          
          expect(application.status).to eq('withdrawn')
          expect(application.rejection_reason).to eq('accepted other offer')
          expect(application.stage_changed_by).to eq(changed_by)
          expect(application.stage_changed_at).to eq(Time.current)
          expect(application.notes).to include('Candidate withdrew')
        end
      end
    end
  end

  describe 'query methods' do
    let(:active_application) { create(:application, status: 'screening') }
    let(:rejected_application) { create(:application, status: 'rejected') }
    let(:withdrawn_application) { create(:application, status: 'withdrawn') }
    let(:accepted_application) { create(:application, status: 'accepted') }
    let(:interview_application) { create(:application, status: 'phone_interview') }

    describe '#active?' do
      it 'returns true for active statuses' do
        expect(active_application.active?).to be true
        expect(interview_application.active?).to be true
      end

      it 'returns false for closed statuses' do
        expect(rejected_application.active?).to be false
        expect(withdrawn_application.active?).to be false
        expect(accepted_application.active?).to be false
      end
    end

    describe '#closed?' do
      it 'returns true for closed statuses' do
        expect(rejected_application.closed?).to be true
        expect(withdrawn_application.closed?).to be true
        expect(accepted_application.closed?).to be true
      end

      it 'returns false for active statuses' do
        expect(active_application.closed?).to be false
      end
    end

    describe '#in_interview_stage?' do
      it 'returns true for interview stages' do
        phone_app = create(:application, status: 'phone_interview')
        tech_app = create(:application, status: 'technical_interview')
        final_app = create(:application, status: 'final_interview')
        
        expect(phone_app.in_interview_stage?).to be true
        expect(tech_app.in_interview_stage?).to be true
        expect(final_app.in_interview_stage?).to be true
      end

      it 'returns false for non-interview stages' do
        expect(active_application.in_interview_stage?).to be false
      end
    end

    describe '#needs_action?' do
      it 'returns true for statuses requiring action' do
        applied_app = create(:application, status: 'applied')
        expect(applied_app.needs_action?).to be true
        expect(active_application.needs_action?).to be true
      end

      it 'returns false for other statuses' do
        expect(interview_application.needs_action?).to be false
      end
    end

    describe '#has_offer?' do
      it 'returns true when salary_offered is present' do
        app_with_offer = create(:application, salary_offered: 75000)
        expect(app_with_offer.has_offer?).to be true
      end

      it 'returns false when salary_offered is nil' do
        app_without_offer = create(:application, salary_offered: nil)
        expect(app_without_offer.has_offer?).to be false
      end
    end

    describe '#rated?' do
      it 'returns true when rating is present' do
        rated_app = create(:application, rating: 4)
        expect(rated_app.rated?).to be true
      end

      it 'returns false when rating is nil' do
        unrated_app = create(:application, rating: nil)
        expect(unrated_app.rated?).to be false
      end
    end

    describe '#highly_rated?' do
      it 'returns true for ratings >= 4' do
        app1 = create(:application, rating: 4)
        app2 = create(:application, rating: 5)
        expect(app1.highly_rated?).to be true
        expect(app2.highly_rated?).to be true
      end

      it 'returns false for ratings < 4 or nil' do
        app1 = create(:application, rating: 3)
        app2 = create(:application, rating: nil)
        expect(app1.highly_rated?).to be false
        expect(app2.highly_rated?).to be false
      end
    end

    describe 'status query methods' do
      it 'provides convenience methods for status checking' do
        expect(rejected_application.rejected?).to be true
        expect(withdrawn_application.withdrawn?).to be true
        expect(accepted_application.accepted?).to be true
        
        expect(rejected_application.accepted?).to be false
      end
    end
  end

  describe 'time-based methods' do
    around do |example|
      freeze_time { example.run }
    end

    let(:application) { create(:application, applied_at: 5.days.ago) }

    describe '#days_since_applied' do
      it 'calculates days since applied' do
        expect(application.days_since_applied).to eq(5)
      end

      it 'returns 0 when applied_at is nil' do
        application.update_column(:applied_at, nil)
        expect(application.days_since_applied).to eq(0)
      end
    end

    describe '#days_in_current_stage' do
      it 'calculates days based on stage_changed_at when present' do
        application.update!(stage_changed_at: 3.days.ago)
        expect(application.days_in_current_stage).to eq(3)
      end

      it 'falls back to applied_at when stage_changed_at is nil' do
        application.update!(stage_changed_at: nil)
        expect(application.days_in_current_stage).to eq(5)
      end

      it 'returns 0 when both timestamps are nil' do
        application.update_columns(applied_at: nil, stage_changed_at: nil)
        expect(application.days_in_current_stage).to eq(0)
      end
    end

    describe '#time_to_hire' do
      it 'calculates time to hire for accepted applications' do
        application.update!(status: 'accepted', updated_at: 1.day.ago)
        expected_days = (1.day.ago.to_date - application.applied_at.to_date).to_i
        expect(application.time_to_hire).to eq(expected_days)
      end

      it 'returns nil for non-accepted applications' do
        expect(application.time_to_hire).to be_nil
      end

      it 'returns nil when applied_at is missing' do
        application.update!(status: 'accepted', applied_at: nil)
        expect(application.time_to_hire).to be_nil
      end
    end
  end

  describe 'formatting methods' do
    describe '#status_humanized' do
      it 'formats interview statuses correctly' do
        app1 = create(:application, status: 'phone_interview')
        app2 = create(:application, status: 'technical_interview')
        app3 = create(:application, status: 'final_interview')
        
        expect(app1.status_humanized).to eq('Phone Interview')
        expect(app2.status_humanized).to eq('Technical Interview')
        expect(app3.status_humanized).to eq('Final Interview')
      end

      it 'humanizes other statuses normally' do
        app = create(:application, status: 'screening')
        expect(app.status_humanized).to eq('Screening')
      end
    end

    describe '#formatted_salary_offered' do
      it 'formats salary with proper delimiters' do
        app = create(:application, salary_offered: 7500000) # $75,000 in cents
        expect(app.formatted_salary_offered).to eq('$75,000')
      end

      it 'returns default message when no offer' do
        app = create(:application, salary_offered: nil)
        expect(app.formatted_salary_offered).to eq('No offer made')
      end
    end

    describe '#source_humanized' do
      it 'formats career_fair correctly' do
        app = create(:application, source: 'career_fair')
        expect(app.source_humanized).to eq('Career Fair')
      end

      it 'humanizes other sources normally' do
        app = create(:application, source: 'linkedin')
        expect(app.source_humanized).to eq('Linkedin')
      end

      it 'returns default for blank source' do
        app = create(:application, source: nil)
        expect(app.source_humanized).to eq('Not specified')
      end
    end

    describe '#rating_display' do
      it 'displays rating with stars' do
        app = create(:application, rating: 4)
        expect(app.rating_display).to eq('4/5 ★★★★☆')
      end

      it 'returns default for unrated' do
        app = create(:application, rating: nil)
        expect(app.rating_display).to eq('Not rated')
      end
    end
  end

  describe 'metadata helpers' do
    let(:application) { create(:application) }

    describe '#set_metadata' do
      it 'sets metadata key-value pairs' do
        application.set_metadata(:source_detail, 'LinkedIn Premium posting')
        expect(application.get_metadata(:source_detail)).to eq('LinkedIn Premium posting')
      end

      it 'merges with existing metadata' do
        application.update!(metadata: { 'existing_key' => 'existing_value' })
        application.set_metadata(:new_key, 'new_value')
        
        expect(application.get_metadata(:existing_key)).to eq('existing_value')
        expect(application.get_metadata(:new_key)).to eq('new_value')
      end

      it 'converts keys to strings' do
        application.set_metadata(:symbol_key, 'symbol_value')
        expect(application.metadata['symbol_key']).to eq('symbol_value')
      end
    end

    describe '#get_metadata' do
      it 'retrieves metadata values' do
        application.update!(metadata: { 'test_key' => 'test_value' })
        expect(application.get_metadata(:test_key)).to eq('test_value')
        expect(application.get_metadata('test_key')).to eq('test_value')
      end

      it 'returns nil for non-existent keys' do
        expect(application.get_metadata(:non_existent)).to be_nil
      end
    end
  end

  describe 'interview management' do
    let(:application) { create(:application) }
    let!(:past_interview) { create(:interview, application: application, scheduled_at: 1.day.ago) }
    let!(:upcoming_interview) { create(:interview, application: application, scheduled_at: 1.day.from_now) }
    let!(:completed_interview) { create(:interview, application: application, status: 'completed', rating: 4) }

    describe '#upcoming_interviews' do
      it 'returns interviews scheduled in the future' do
        freeze_time do
          result = application.upcoming_interviews
          expect(result).to include(upcoming_interview)
          expect(result).not_to include(past_interview)
        end
      end

      it 'orders by scheduled_at' do
        later_interview = create(:interview, application: application, scheduled_at: 2.days.from_now)
        freeze_time do
          result = application.upcoming_interviews
          expect(result.first).to eq(upcoming_interview)
          expect(result.last).to eq(later_interview)
        end
      end
    end

    describe '#past_interviews' do
      it 'returns interviews scheduled in the past' do
        freeze_time do
          result = application.past_interviews
          expect(result).to include(past_interview)
          expect(result).not_to include(upcoming_interview)
        end
      end
    end

    describe '#completed_interviews' do
      it 'returns interviews with completed status' do
        result = application.completed_interviews
        expect(result).to include(completed_interview)
      end
    end

    describe '#average_interview_rating' do
      it 'calculates average rating of completed interviews' do
        create(:interview, application: application, status: 'completed', rating: 2)
        expect(application.average_interview_rating).to eq(3.0) # (4 + 2) / 2
      end

      it 'returns nil when no rated completed interviews' do
        application.interviews.destroy_all
        expect(application.average_interview_rating).to be_nil
      end

      it 'ignores unrated completed interviews' do
        create(:interview, application: application, status: 'completed', rating: nil)
        expect(application.average_interview_rating).to eq(4.0) # Only the rated one
      end
    end
  end

  describe 'class methods' do
    before do
      create(:application, status: 'applied')
      create(:application, status: 'applied')
      create(:application, status: 'screening')
      create(:application, status: 'accepted')
      create(:application, status: 'rejected')
    end

    describe '.by_pipeline_stage' do
      it 'groups applications by status' do
        result = Application.by_pipeline_stage
        expect(result['applied']).to eq(2)
        expect(result['screening']).to eq(1)
        expect(result['accepted']).to eq(1)
        expect(result['rejected']).to eq(1)
      end
    end

    describe '.conversion_rate' do
      it 'calculates conversion rate between stages' do
        # 2 applied, 1 accepted = 50% conversion
        rate = Application.conversion_rate('applied', 'accepted')
        expect(rate).to eq(50.0)
      end

      it 'returns 0 when no applications in from_status' do
        rate = Application.conversion_rate('non_existent', 'accepted')
        expect(rate).to eq(0)
      end
    end

    describe '.average_time_to_hire' do
      it 'calculates average time to hire for accepted applications' do
        # Create applications with known time to hire
        freeze_time do
          app1 = create(:application, status: 'accepted', applied_at: 10.days.ago, updated_at: Time.current)
          app2 = create(:application, status: 'accepted', applied_at: 20.days.ago, updated_at: Time.current)
          
          # Average should be (10 + 20) / 2 = 15 days
          expect(Application.average_time_to_hire).to eq(15.0)
        end
      end

      it 'returns 0 when no accepted applications' do
        Application.where(status: 'accepted').destroy_all
        expect(Application.average_time_to_hire).to eq(0)
      end
    end

    describe '.source_breakdown' do
      before do
        create(:application, source: 'linkedin')
        create(:application, source: 'linkedin')
        create(:application, source: 'indeed')
        create(:application, source: nil)
      end

      it 'groups applications by source, excluding nil values' do
        result = Application.source_breakdown
        expect(result['linkedin']).to eq(2)
        expect(result['indeed']).to eq(1)
        expect(result).not_to have_key(nil)
      end
    end
  end

  describe 'JSONB metadata field' do
    let(:application) { create(:application) }

    it 'stores and retrieves complex metadata' do
      metadata = {
        'source_details' => {
          'campaign_id' => 'summer_2023',
          'referrer_id' => '12345'
        },
        'screening_scores' => [85, 92, 78],
        'tags' => ['urgent', 'senior_level']
      }
      
      application.update!(metadata: metadata)
      application.reload
      
      expect(application.metadata['source_details']['campaign_id']).to eq('summer_2023')
      expect(application.metadata['screening_scores']).to eq([85, 92, 78])
      expect(application.metadata['tags']).to include('urgent')
    end

    it 'queries JSONB data' do
      application.update!(metadata: { 'priority' => 'high', 'source_campaign' => 'q4_hiring' })
      other_app = create(:application, metadata: { 'priority' => 'low' })
      
      # Query applications with high priority
      high_priority = Application.where("metadata->>'priority' = ?", 'high')
      expect(high_priority).to include(application)
      expect(high_priority).not_to include(other_app)
    end
  end

  describe 'performance considerations' do
    it 'includes associations to prevent N+1 queries' do
      # Test basic query structure
      company = create(:company)
      job = create(:job, company: company)
      create_list(:application, 3, company: company, job: job)

      # Test that scopes work properly
      applications = Application.for_company(company).includes(:candidate, :job)
      expect(applications.count).to eq(3)
      
      applications.each do |app|
        expect(app.candidate_full_name).to be_present
        expect(app.job_title).to be_present
      end
    end
  end

  # Edge cases and error handling
  describe 'edge cases' do
    it 'handles empty metadata gracefully' do
      application = create(:application, metadata: {})
      expect(application.get_metadata(:non_existent)).to be_nil
      application.set_metadata(:new_key, 'value')
      expect(application.get_metadata(:new_key)).to eq('value')
    end

    it 'validates metadata presence even when empty' do
      application = build(:application, metadata: nil)
      expect(application).not_to be_valid
      expect(application.errors[:metadata]).to include("can't be blank")
    end

    it 'handles very long rejection reasons' do
      long_reason = 'a' * 256
      application = build(:application, rejection_reason: long_reason)
      expect(application).not_to be_valid
      expect(application.errors[:rejection_reason]).to include('is too long (maximum is 255 characters)')
    end
  end
end