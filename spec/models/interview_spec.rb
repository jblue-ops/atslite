# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Interview, type: :model do
  # Factory setup
  let(:company) { create(:company) }
  let(:candidate) { create(:candidate) }
  let(:job) { create(:job, company: company) }
  let(:application) { create(:application, job: job, candidate: candidate, company: company) }
  let(:interviewer) { create(:user, company: company) }
  let(:scheduled_by) { create(:user, company: company) }
  
  describe 'associations' do
    it { should belong_to(:application) }
    it { should belong_to(:interviewer).class_name('User') }
    it { should belong_to(:scheduled_by).class_name('User').optional }
    it { should have_one(:candidate).through(:application) }
    it { should have_one(:job).through(:application) }
    it { should have_one(:company).through(:application) }
  end

  describe 'validations' do
    subject { build(:interview, application: application, interviewer: interviewer) }

    context 'presence validations' do
      it { should validate_presence_of(:application_id) }
      it { should validate_presence_of(:interviewer_id) }
      it { should validate_presence_of(:interview_type) }
      it { should validate_presence_of(:status) }
      it { should validate_presence_of(:scheduled_at) }
      it { should validate_presence_of(:duration_minutes) }
      it { should validate_presence_of(:metadata) }
    end

    context 'duration validation' do
      it { should validate_numericality_of(:duration_minutes).is_greater_than(0) }
      it { should validate_numericality_of(:duration_minutes).is_less_than_or_equal_to(480) }
      
      it 'allows valid durations' do
        interview = build(:interview, duration_minutes: 60)
        expect(interview).to be_valid
      end

      it 'rejects zero duration' do
        interview = build(:interview, duration_minutes: 0)
        expect(interview).not_to be_valid
        expect(interview.errors[:duration_minutes]).to include('must be between 1 and 480 minutes')
      end

      it 'rejects duration over 8 hours' do
        interview = build(:interview, duration_minutes: 500)
        expect(interview).not_to be_valid
        expect(interview.errors[:duration_minutes]).to include('must be between 1 and 480 minutes')
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

      it 'has proper error message for invalid rating' do
        interview = build(:interview, rating: 6)
        interview.valid?
        expect(interview.errors[:rating]).to include('must be between 1 and 5')
      end
    end

    context 'string length validations' do
      it { should validate_length_of(:location).is_at_most(255) }
      it { should validate_length_of(:video_link).is_at_most(500) }
      it { should validate_length_of(:calendar_event_id).is_at_most(100) }
      it { should validate_length_of(:feedback).is_at_most(2000) }
      it { should validate_length_of(:notes).is_at_most(1000) }
    end

    context 'video link format validation' do
      it 'accepts valid HTTP URLs' do
        interview = build(:interview, video_link: 'http://meet.google.com/abc-def-ghi')
        expect(interview).to be_valid
      end

      it 'accepts valid HTTPS URLs' do
        interview = build(:interview, video_link: 'https://zoom.us/j/123456789')
        expect(interview).to be_valid
      end

      it 'rejects invalid URL formats' do
        interview = build(:interview, video_link: 'not-a-url')
        expect(interview).not_to be_valid
        expect(interview.errors[:video_link]).to include('must be a valid URL')
      end

      it 'allows blank video links' do
        interview = build(:interview, video_link: '')
        expect(interview).to be_valid
      end
    end

    context 'custom validations' do
      describe 'completion_data_consistency' do
        it 'requires completed_at when status is completed' do
          interview = build(:interview, status: 'completed', completed_at: nil)
          expect(interview).not_to be_valid
          expect(interview.errors[:completed_at]).to include('must be present when status is completed')
        end

        it 'requires completed_at to be blank when status is not completed' do
          interview = build(:interview, status: 'scheduled', completed_at: Time.current)
          expect(interview).not_to be_valid
          expect(interview.errors[:completed_at]).to include('must be blank when status is not completed')
        end

        it 'allows completed_at when status is completed' do
          interview = build(:interview, status: 'completed', completed_at: Time.current)
          expect(interview).to be_valid
        end
      end

      describe 'interviewer_belongs_to_company' do
        it 'requires interviewer to belong to same company as application' do
          other_company = create(:company)
          other_interviewer = create(:user, company: other_company)
          interview = build(:interview, application: application, interviewer: other_interviewer)
          
          expect(interview).not_to be_valid
          expect(interview.errors[:interviewer]).to include('must belong to the same company as the application')
        end

        it 'allows interviewer from same company' do
          interview = build(:interview, application: application, interviewer: interviewer)
          expect(interview).to be_valid
        end
      end

      describe 'scheduled_by_belongs_to_company' do
        it 'requires scheduled_by to belong to same company as application' do
          other_company = create(:company)
          other_user = create(:user, company: other_company)
          interview = build(:interview, application: application, scheduled_by: other_user)
          
          expect(interview).not_to be_valid
          expect(interview.errors[:scheduled_by]).to include('must belong to the same company as the application')
        end

        it 'allows scheduled_by from same company' do
          interview = build(:interview, application: application, scheduled_by: scheduled_by)
          expect(interview).to be_valid
        end

        it 'allows nil scheduled_by' do
          interview = build(:interview, application: application, scheduled_by: nil)
          expect(interview).to be_valid
        end
      end

      describe 'location_required_for_onsite' do
        it 'requires location for onsite interviews' do
          interview = build(:interview, interview_type: 'onsite', location: nil)
          expect(interview).not_to be_valid
          expect(interview.errors[:location]).to include('is required for onsite interviews')
        end

        it 'allows blank location for non-onsite interviews' do
          interview = build(:interview, interview_type: 'phone', location: nil)
          expect(interview).to be_valid
        end

        it 'allows location for onsite interviews' do
          interview = build(:interview, interview_type: 'onsite', location: 'Conference Room A')
          expect(interview).to be_valid
        end
      end

      describe 'video_link_required_for_video_calls' do
        it 'requires video_link for video interviews' do
          interview = build(:interview, interview_type: 'video', video_link: nil)
          expect(interview).not_to be_valid
          expect(interview.errors[:video_link]).to include('is required for video interviews')
        end

        it 'allows blank video_link for non-video interviews' do
          interview = build(:interview, interview_type: 'phone', video_link: nil)
          expect(interview).to be_valid
        end

        it 'allows video_link for video interviews' do
          interview = build(:interview, interview_type: 'video', video_link: 'https://zoom.us/j/123456789')
          expect(interview).to be_valid
        end
      end

      describe 'scheduled_at_not_in_past' do
        it 'does not allow scheduled_at in the past on create' do
          interview = build(:interview, scheduled_at: 1.hour.ago)
          expect(interview).not_to be_valid
          expect(interview.errors[:scheduled_at]).to include('must be in the future')
        end

        it 'allows scheduled_at in the future on create' do
          interview = build(:interview, scheduled_at: 1.hour.from_now)
          expect(interview).to be_valid
        end

        it 'allows past scheduled_at on update' do
          interview = create(:interview, scheduled_at: 1.hour.from_now)
          interview.update(notes: 'Updated notes', scheduled_at: 1.hour.ago)
          expect(interview).to be_valid
        end
      end

      describe 'decision_requires_completion' do
        it 'allows decision when interview is completed' do
          interview = build(:interview, status: 'completed', decision: 'yes', completed_at: Time.current)
          expect(interview).to be_valid
        end

        it 'does not allow decision when interview is not completed' do
          interview = build(:interview, status: 'scheduled', decision: 'yes')
          expect(interview).not_to be_valid
          expect(interview.errors[:decision]).to include('can only be set when interview is completed')
        end

        it 'allows nil decision for non-completed interviews' do
          interview = build(:interview, status: 'scheduled', decision: nil)
          expect(interview).to be_valid
        end
      end
    end
  end

  describe 'enums' do
    describe 'interview_type' do
      let(:types) { %w[phone video onsite technical behavioral panel] }

      it 'defines all expected interview types' do
        expect(Interview.interview_types.keys).to match_array(types)
      end

      it 'defines predicate methods for all types' do
        types.each do |type|
          interview = create(:interview, interview_type: type, 
                             location: (type == 'onsite' ? 'Office' : nil),
                             video_link: (type == 'video' ? 'https://zoom.us/j/123' : nil))
          expect(interview.send("interview_type_#{type}?")).to be true
        end
      end

      it 'prefixes enum methods correctly' do
        interview = create(:interview, interview_type: 'phone')
        expect(interview.interview_type_phone?).to be true
        expect(interview.interview_type_video?).to be false
      end
    end

    describe 'status' do
      let(:statuses) { %w[scheduled confirmed completed cancelled no_show] }

      it 'defines all expected statuses' do
        expect(Interview.statuses.keys).to match_array(statuses)
      end

      it 'defines predicate methods for all statuses' do
        statuses.each do |status|
          interview_attrs = { status: status }
          interview_attrs[:completed_at] = Time.current if status == 'completed'
          
          interview = create(:interview, interview_attrs)
          expect(interview.send("status_#{status}?")).to be true
        end
      end

      it 'prefixes enum methods correctly' do
        interview = create(:interview, status: 'scheduled')
        expect(interview.status_scheduled?).to be true
        expect(interview.status_completed?).to be false
      end
    end

    describe 'decision' do
      let(:decisions) { %w[strong_yes yes maybe no strong_no] }

      it 'defines all expected decisions' do
        expect(Interview.decisions.keys).to match_array(decisions)
      end

      it 'allows nil decisions' do
        interview = create(:interview, decision: nil)
        expect(interview.decision).to be_nil
      end

      it 'defines predicate methods for all decisions' do
        decisions.each do |decision|
          interview = create(:interview, status: 'completed', decision: decision, completed_at: Time.current)
          expect(interview.send("decision_#{decision}?")).to be true
        end
      end

      it 'prefixes enum methods correctly' do
        interview = create(:interview, status: 'completed', decision: 'yes', completed_at: Time.current)
        expect(interview.decision_yes?).to be true
        expect(interview.decision_no?).to be false
      end
    end
  end

  describe 'callbacks' do
    describe 'before_validation callbacks' do
      describe 'set_default_duration' do
        it 'sets default duration for phone interviews' do
          interview = build(:interview, interview_type: 'phone', duration_minutes: nil)
          interview.valid?
          expect(interview.duration_minutes).to eq(30)
        end

        it 'sets default duration for video interviews' do
          interview = build(:interview, interview_type: 'video', duration_minutes: nil, video_link: 'https://zoom.us/j/123')
          interview.valid?
          expect(interview.duration_minutes).to eq(45)
        end

        it 'sets default duration for technical interviews' do
          interview = build(:interview, interview_type: 'technical', duration_minutes: nil)
          interview.valid?
          expect(interview.duration_minutes).to eq(90)
        end

        it 'sets default duration for panel interviews' do
          interview = build(:interview, interview_type: 'panel', duration_minutes: nil)
          interview.valid?
          expect(interview.duration_minutes).to eq(90)
        end

        it 'sets default duration for behavioral interviews' do
          interview = build(:interview, interview_type: 'behavioral', duration_minutes: nil)
          interview.valid?
          expect(interview.duration_minutes).to eq(60)
        end

        it 'sets default duration for onsite interviews' do
          interview = build(:interview, interview_type: 'onsite', duration_minutes: nil, location: 'Office')
          interview.valid?
          expect(interview.duration_minutes).to eq(60)
        end

        it 'does not override existing duration' do
          interview = build(:interview, interview_type: 'phone', duration_minutes: 45)
          interview.valid?
          expect(interview.duration_minutes).to eq(45)
        end
      end

      describe 'normalize_video_link' do
        it 'adds https:// prefix when missing protocol' do
          interview = build(:interview, interview_type: 'video', video_link: 'zoom.us/j/123456789')
          interview.valid?
          expect(interview.video_link).to eq('https://zoom.us/j/123456789')
        end

        it 'preserves existing http:// prefix' do
          interview = build(:interview, interview_type: 'video', video_link: 'http://meet.google.com/abc-def-ghi')
          interview.valid?
          expect(interview.video_link).to eq('http://meet.google.com/abc-def-ghi')
        end

        it 'preserves existing https:// prefix' do
          interview = build(:interview, interview_type: 'video', video_link: 'https://teams.microsoft.com/l/meetup-join/123')
          interview.valid?
          expect(interview.video_link).to eq('https://teams.microsoft.com/l/meetup-join/123')
        end

        it 'strips whitespace' do
          interview = build(:interview, interview_type: 'video', video_link: '  https://zoom.us/j/123  ')
          interview.valid?
          expect(interview.video_link).to eq('https://zoom.us/j/123')
        end

        it 'does nothing when video_link is blank' do
          interview = build(:interview, video_link: '')
          interview.valid?
          expect(interview.video_link).to eq('')
        end
      end
    end

    describe 'after_update callbacks' do
      it 'updates completion timestamp when status changes to completed' do
        interview = create(:interview, status: 'scheduled')
        
        freeze_time do
          interview.update!(status: 'completed')
          expect(interview.reload.completed_at).to eq(Time.current)
        end
      end

      it 'clears completion timestamp when status changes from completed' do
        interview = create(:interview, status: 'completed', completed_at: 1.day.ago)
        interview.update!(status: 'scheduled')
        expect(interview.reload.completed_at).to be_nil
      end
    end

    describe 'after_create and after_update callbacks' do
      it 'triggers application status update callback on create' do
        # This would test the update_application_status_if_needed callback
        # Implementation would depend on specific business rules
        expect { create(:interview, application: application) }.not_to raise_error
      end

      it 'triggers application status update callback on status change' do
        interview = create(:interview, application: application)
        expect { interview.update!(status: 'completed', completed_at: Time.current) }.not_to raise_error
      end
    end
  end

  describe 'scopes' do
    let!(:application1) { create(:application) }
    let!(:application2) { create(:application) }
    let!(:interviewer1) { create(:user, company: application1.company) }
    let!(:interviewer2) { create(:user, company: application2.company) }

    before do
      @interview1 = create(:interview, application: application1, interviewer: interviewer1,
                          interview_type: 'phone', status: 'scheduled', rating: 4,
                          scheduled_at: 2.days.from_now, decision: nil)
      @interview2 = create(:interview, application: application1, interviewer: interviewer1,
                          interview_type: 'technical', status: 'completed', rating: 3,
                          scheduled_at: 1.day.ago, decision: 'yes', completed_at: Time.current)
      @interview3 = create(:interview, application: application2, interviewer: interviewer2,
                          interview_type: 'video', status: 'cancelled', rating: nil,
                          scheduled_at: 1.day.from_now, decision: nil,
                          video_link: 'https://zoom.us/j/123')
      @interview4 = create(:interview, application: application2, interviewer: interviewer2,
                          interview_type: 'onsite', status: 'no_show', rating: 1,
                          scheduled_at: 3.days.ago, decision: 'strong_no',
                          location: 'Main Office')
    end

    describe 'basic scopes' do
      it 'filters by application' do
        expect(Interview.for_application(application1)).to contain_exactly(@interview1, @interview2)
      end

      it 'filters by interviewer' do
        expect(Interview.for_interviewer(interviewer1)).to contain_exactly(@interview1, @interview2)
      end

      it 'filters by company' do
        expect(Interview.for_company(application1.company)).to contain_exactly(@interview1, @interview2)
      end

      it 'filters by type' do
        expect(Interview.by_type('phone')).to contain_exactly(@interview1)
      end

      it 'filters by status' do
        expect(Interview.by_status('completed')).to contain_exactly(@interview2)
      end

      it 'filters by decision' do
        expect(Interview.by_decision('yes')).to contain_exactly(@interview2)
      end

      it 'filters by rating' do
        expect(Interview.with_rating(4)).to contain_exactly(@interview1)
      end
    end

    describe 'timeline scopes' do
      it 'filters interviews between dates' do
        freeze_time do
          result = Interview.scheduled_between(1.day.ago, 3.days.from_now)
          expect(result).to include(@interview1, @interview2, @interview3)
          expect(result).not_to include(@interview4)
        end
      end

      it 'filters interviews for specific date' do
        freeze_time do
          today_interview = create(:interview, scheduled_at: Time.current.midday)
          result = Interview.scheduled_for_date(Date.current)
          expect(result).to include(today_interview)
        end
      end

      it 'finds interviews scheduled today' do
        freeze_time do
          today_interview = create(:interview, scheduled_at: Time.current + 2.hours)
          result = Interview.scheduled_today
          expect(result).to include(today_interview)
        end
      end

      it 'finds interviews scheduled tomorrow' do
        freeze_time do
          tomorrow_interview = create(:interview, scheduled_at: 1.day.from_now + 2.hours)
          result = Interview.scheduled_tomorrow
          expect(result).to include(tomorrow_interview)
        end
      end

      it 'finds interviews scheduled this week' do
        freeze_time do
          result = Interview.scheduled_this_week
          expect(result).to include(@interview1, @interview3)
        end
      end

      it 'finds upcoming interviews' do
        freeze_time do
          result = Interview.upcoming
          expect(result).to include(@interview1, @interview3)
          expect(result).not_to include(@interview2, @interview4)
          expect(result.to_a).to eq([@interview3, @interview1]) # ordered by scheduled_at
        end
      end

      it 'finds past interviews' do
        freeze_time do
          result = Interview.past
          expect(result).to include(@interview2, @interview4)
          expect(result).not_to include(@interview1, @interview3)
        end
      end

      it 'orders by recent scheduled time' do
        result = Interview.recent
        expect(result.first).to eq(@interview1) # 2 days from now (most recent)
      end
    end

    describe 'status-based scopes' do
      it 'finds active interviews' do
        expect(Interview.active).to contain_exactly(@interview1)
      end

      it 'finds completed interviews' do
        expect(Interview.completed).to contain_exactly(@interview2)
      end

      it 'finds cancelled interviews' do
        expect(Interview.cancelled).to contain_exactly(@interview3)
      end

      it 'finds no-show interviews' do
        expect(Interview.no_shows).to contain_exactly(@interview4)
      end

      it 'finds interviews needing feedback' do
        completed_without_feedback = create(:interview, status: 'completed', 
                                            completed_at: Time.current, feedback: nil)
        expect(Interview.needs_feedback).to include(completed_without_feedback)
        expect(Interview.needs_feedback).not_to include(@interview2) # has feedback via factory
      end

      it 'finds interviews with feedback' do
        # Assuming @interview2 has feedback from factory trait
        completed_with_feedback = create(:interview, status: 'completed', 
                                        completed_at: Time.current, feedback: 'Great interview')
        expect(Interview.with_feedback).to include(completed_with_feedback)
      end
    end

    describe 'decision and rating scopes' do
      it 'finds interviews with positive decisions' do
        strong_yes_interview = create(:interview, status: 'completed', decision: 'strong_yes', 
                                     completed_at: Time.current)
        expect(Interview.positive_decisions).to contain_exactly(@interview2, strong_yes_interview)
      end

      it 'finds interviews with negative decisions' do
        no_interview = create(:interview, status: 'completed', decision: 'no', completed_at: Time.current)
        expect(Interview.negative_decisions).to contain_exactly(@interview4, no_interview)
      end

      it 'finds interviews with neutral decisions' do
        maybe_interview = create(:interview, status: 'completed', decision: 'maybe', completed_at: Time.current)
        expect(Interview.neutral_decisions).to contain_exactly(maybe_interview)
      end

      it 'finds highly rated interviews' do
        highly_rated = create(:interview, rating: 5)
        expect(Interview.highly_rated).to contain_exactly(@interview1, highly_rated)
      end

      it 'finds poorly rated interviews' do
        expect(Interview.poorly_rated).to contain_exactly(@interview4)
      end

      it 'finds rated interviews' do
        expect(Interview.rated).to contain_exactly(@interview1, @interview2, @interview4)
      end

      it 'finds unrated interviews' do
        expect(Interview.unrated).to contain_exactly(@interview3)
      end
    end

    describe 'duration and type scopes' do
      before do
        @short_interview = create(:interview, duration_minutes: 20)
        @long_interview = create(:interview, duration_minutes: 150)
      end

      it 'finds short interviews' do
        expect(Interview.short_interviews).to include(@short_interview)
      end

      it 'finds long interviews' do
        expect(Interview.long_interviews).to include(@long_interview)
      end

      it 'finds remote interviews' do
        expect(Interview.remote_interviews).to contain_exactly(@interview1, @interview3)
      end

      it 'finds in-person interviews' do
        expect(Interview.in_person_interviews).to contain_exactly(@interview4)
      end

      it 'finds technical interviews' do
        expect(Interview.technical_interviews).to contain_exactly(@interview2)
      end
    end

    describe 'search and filtering scopes' do
      before do
        @interview_with_feedback = create(:interview, feedback: 'excellent technical skills',
                                         notes: 'great communication during interview')
        @interview_with_calendar = create(:interview, calendar_event_id: 'cal_event_123')
      end

      it 'searches in feedback and notes' do
        result = Interview.search_in_feedback('technical')
        expect(result).to include(@interview_with_feedback)
        
        result = Interview.search_in_feedback('communication')
        expect(result).to include(@interview_with_feedback)
      end

      it 'finds interviews with calendar events' do
        expect(Interview.with_calendar_event).to include(@interview_with_calendar)
      end
    end
  end

  describe 'delegations' do
    let(:interview) { create(:interview, application: application, interviewer: interviewer, scheduled_by: scheduled_by) }

    it 'delegates candidate methods with prefix' do
      expect(interview.candidate_full_name).to eq(interview.candidate.full_name)
      expect(interview.candidate_email).to eq(interview.candidate.email)
    end

    it 'delegates job title with prefix' do
      expect(interview.job_title).to eq(interview.job.title)
    end

    it 'delegates company name with prefix' do
      expect(interview.company_name).to eq(interview.company.name)
    end

    it 'delegates interviewer methods with prefix' do
      expect(interview.interviewer_full_name).to eq(interviewer.full_name)
      expect(interview.interviewer_email).to eq(interviewer.email)
    end

    it 'delegates scheduled_by full_name with prefix and allows nil' do
      interview_with_scheduled_by = create(:interview, scheduled_by: scheduled_by)
      interview_without_scheduled_by = create(:interview, scheduled_by: nil)
      
      expect(interview_with_scheduled_by.scheduled_by_full_name).to eq(scheduled_by.full_name)
      expect(interview_without_scheduled_by.scheduled_by_full_name).to be_nil
    end
  end

  describe 'state transition methods' do
    let(:interview) { create(:interview, status: 'scheduled', scheduled_at: 1.hour.from_now) }

    describe '#confirm!' do
      it 'confirms a scheduled interview' do
        expect(interview.confirm!).to be true
        expect(interview.status).to eq('confirmed')
      end

      it 'returns false if interview cannot be confirmed' do
        interview.update!(status: 'completed', completed_at: Time.current)
        expect(interview.confirm!).to be false
      end
    end

    describe '#complete!' do
      it 'completes an interview with feedback and rating' do
        freeze_time do
          travel_to(interview.scheduled_at + 30.minutes) do
            result = interview.complete!(feedback: 'Great interview', rating: 5, 
                                       decision: 'strong_yes', notes: 'Hire immediately')
            
            expect(result).to be true
            expect(interview.status).to eq('completed')
            expect(interview.completed_at).to eq(Time.current)
            expect(interview.feedback).to eq('Great interview')
            expect(interview.rating).to eq(5)
            expect(interview.decision).to eq('strong_yes')
            expect(interview.notes).to eq('Hire immediately')
          end
        end
      end

      it 'completes without optional parameters' do
        travel_to(interview.scheduled_at + 30.minutes) do
          expect(interview.complete!).to be true
          expect(interview.status).to eq('completed')
          expect(interview.completed_at).to be_present
        end
      end

      it 'returns false if interview cannot be completed' do
        expect(interview.complete!).to be false # scheduled_at is in future
      end

      it 'returns false for already completed interview' do
        interview.update!(status: 'completed', completed_at: Time.current)
        expect(interview.complete!).to be false
      end
    end

    describe '#cancel!' do
      it 'cancels an interview with reason' do
        result = interview.cancel!(reason: 'Interviewer sick')
        
        expect(result).to be true
        expect(interview.status).to eq('cancelled')
        expect(interview.notes).to include('Cancelled: Interviewer sick')
      end

      it 'cancels without reason' do
        expect(interview.cancel!).to be true
        expect(interview.status).to eq('cancelled')
      end

      it 'returns false if interview cannot be cancelled' do
        interview.update!(status: 'completed', completed_at: Time.current)
        expect(interview.cancel!).to be false
      end

      it 'appends reason to existing notes' do
        interview.update!(notes: 'Existing notes')
        interview.cancel!(reason: 'Scheduling conflict')
        expect(interview.notes).to include('Existing notes')
        expect(interview.notes).to include('Cancelled: Scheduling conflict')
      end
    end

    describe '#mark_no_show!' do
      it 'marks interview as no show' do
        travel_to(interview.scheduled_at + 1.hour) do
          result = interview.mark_no_show!(notes: 'Candidate did not show up')
          
          expect(result).to be true
          expect(interview.status).to eq('no_show')
          expect(interview.notes).to include('Candidate did not show up')
        end
      end

      it 'returns false if interview cannot be marked as no show' do
        expect(interview.mark_no_show!).to be false # scheduled_at is in future
      end

      it 'returns false for completed interview' do
        interview.update!(status: 'completed', completed_at: Time.current)
        expect(interview.mark_no_show!).to be false
      end
    end

    describe '#reschedule!' do
      let(:new_time) { 2.days.from_now }
      let(:rescheduler) { create(:user, company: interview.application.company) }

      it 'reschedules an interview' do
        result = interview.reschedule!(new_time: new_time, changed_by: rescheduler, 
                                     reason: 'Interviewer conflict')
        
        expect(result).to be true
        expect(interview.scheduled_at).to eq(new_time)
        expect(interview.scheduled_by).to eq(rescheduler)
        expect(interview.status).to eq('scheduled')
        expect(interview.notes).to include('Rescheduled: Interviewer conflict')
      end

      it 'reschedules without changed_by and reason' do
        original_scheduled_by = interview.scheduled_by
        result = interview.reschedule!(new_time: new_time)
        
        expect(result).to be true
        expect(interview.scheduled_at).to eq(new_time)
        expect(interview.scheduled_by).to eq(original_scheduled_by)
      end

      it 'returns false if interview cannot be rescheduled' do
        interview.update!(status: 'completed', completed_at: Time.current)
        expect(interview.reschedule!(new_time: new_time)).to be false
      end
    end
  end

  describe 'query methods' do
    let(:scheduled_interview) { create(:interview, status: 'scheduled', scheduled_at: 1.hour.from_now) }
    let(:confirmed_interview) { create(:interview, status: 'confirmed', scheduled_at: 1.hour.from_now) }
    let(:completed_interview) { create(:interview, status: 'completed', scheduled_at: 1.hour.ago, completed_at: Time.current) }
    let(:cancelled_interview) { create(:interview, status: 'cancelled') }

    describe '#can_be_confirmed?' do
      it 'returns true for scheduled interviews' do
        expect(scheduled_interview.can_be_confirmed?).to be true
      end

      it 'returns false for non-scheduled interviews' do
        expect(confirmed_interview.can_be_confirmed?).to be false
        expect(completed_interview.can_be_confirmed?).to be false
      end
    end

    describe '#can_be_completed?' do
      it 'returns true for scheduled/confirmed interviews in the past' do
        travel_to(scheduled_interview.scheduled_at + 1.hour) do
          expect(scheduled_interview.can_be_completed?).to be true
        end
        travel_to(confirmed_interview.scheduled_at + 1.hour) do
          expect(confirmed_interview.can_be_completed?).to be true
        end
      end

      it 'returns false for future interviews' do
        expect(scheduled_interview.can_be_completed?).to be false
        expect(confirmed_interview.can_be_completed?).to be false
      end

      it 'returns false for completed/cancelled interviews' do
        expect(completed_interview.can_be_completed?).to be false
        expect(cancelled_interview.can_be_completed?).to be false
      end
    end

    describe '#can_be_cancelled?' do
      it 'returns true for scheduled/confirmed interviews' do
        expect(scheduled_interview.can_be_cancelled?).to be true
        expect(confirmed_interview.can_be_cancelled?).to be true
      end

      it 'returns false for completed/cancelled interviews' do
        expect(completed_interview.can_be_cancelled?).to be false
        expect(cancelled_interview.can_be_cancelled?).to be false
      end
    end

    describe '#can_be_marked_no_show?' do
      it 'returns true for scheduled/confirmed past interviews' do
        travel_to(scheduled_interview.scheduled_at + 1.hour) do
          expect(scheduled_interview.can_be_marked_no_show?).to be true
        end
        travel_to(confirmed_interview.scheduled_at + 1.hour) do
          expect(confirmed_interview.can_be_marked_no_show?).to be true
        end
      end

      it 'returns false for future interviews' do
        expect(scheduled_interview.can_be_marked_no_show?).to be false
      end

      it 'returns false for completed/cancelled interviews' do
        expect(completed_interview.can_be_marked_no_show?).to be false
        expect(cancelled_interview.can_be_marked_no_show?).to be false
      end
    end

    describe '#can_be_rescheduled?' do
      it 'returns true for scheduled/confirmed interviews' do
        expect(scheduled_interview.can_be_rescheduled?).to be true
        expect(confirmed_interview.can_be_rescheduled?).to be true
      end

      it 'returns false for completed/cancelled interviews' do
        expect(completed_interview.can_be_rescheduled?).to be false
        expect(cancelled_interview.can_be_rescheduled?).to be false
      end
    end

    describe '#is_upcoming?' do
      it 'returns true for scheduled/confirmed future interviews' do
        expect(scheduled_interview.is_upcoming?).to be true
        expect(confirmed_interview.is_upcoming?).to be true
      end

      it 'returns false for past interviews' do
        past_interview = create(:interview, status: 'scheduled', scheduled_at: 1.hour.ago)
        expect(past_interview.is_upcoming?).to be false
      end

      it 'returns false for completed/cancelled interviews' do
        expect(completed_interview.is_upcoming?).to be false
        expect(cancelled_interview.is_upcoming?).to be false
      end
    end

    describe '#is_today?' do
      it 'returns true for interviews scheduled today' do
        today_interview = create(:interview, scheduled_at: Time.current + 2.hours)
        expect(today_interview.is_today?).to be true
      end

      it 'returns false for interviews not scheduled today' do
        expect(scheduled_interview.is_today?).to be false
      end
    end

    describe '#is_overdue?' do
      it 'returns true for scheduled/confirmed past interviews' do
        travel_to(scheduled_interview.scheduled_at + 1.hour) do
          expect(scheduled_interview.is_overdue?).to be true
        end
      end

      it 'returns false for future interviews' do
        expect(scheduled_interview.is_overdue?).to be false
      end

      it 'returns false for completed/cancelled interviews' do
        expect(completed_interview.is_overdue?).to be false
        expect(cancelled_interview.is_overdue?).to be false
      end
    end

    describe '#requires_location?' do
      it 'returns true for onsite interviews' do
        onsite_interview = create(:interview, interview_type: 'onsite', location: 'Office')
        expect(onsite_interview.requires_location?).to be true
      end

      it 'returns false for non-onsite interviews' do
        phone_interview = create(:interview, interview_type: 'phone')
        expect(phone_interview.requires_location?).to be false
      end
    end

    describe '#requires_video_link?' do
      it 'returns true for video interviews' do
        video_interview = create(:interview, interview_type: 'video', video_link: 'https://zoom.us/j/123')
        expect(video_interview.requires_video_link?).to be true
      end

      it 'returns false for non-video interviews' do
        phone_interview = create(:interview, interview_type: 'phone')
        expect(phone_interview.requires_video_link?).to be false
      end
    end

    describe '#is_remote?' do
      it 'returns true for phone and video interviews' do
        phone_interview = create(:interview, interview_type: 'phone')
        video_interview = create(:interview, interview_type: 'video', video_link: 'https://zoom.us/j/123')
        
        expect(phone_interview.is_remote?).to be true
        expect(video_interview.is_remote?).to be true
      end

      it 'returns false for onsite interviews' do
        onsite_interview = create(:interview, interview_type: 'onsite', location: 'Office')
        expect(onsite_interview.is_remote?).to be false
      end
    end

    describe '#has_positive_decision?' do
      it 'returns true for strong_yes and yes decisions' do
        strong_yes_interview = create(:interview, status: 'completed', decision: 'strong_yes', completed_at: Time.current)
        yes_interview = create(:interview, status: 'completed', decision: 'yes', completed_at: Time.current)
        
        expect(strong_yes_interview.has_positive_decision?).to be true
        expect(yes_interview.has_positive_decision?).to be true
      end

      it 'returns false for other decisions' do
        maybe_interview = create(:interview, status: 'completed', decision: 'maybe', completed_at: Time.current)
        no_interview = create(:interview, status: 'completed', decision: 'no', completed_at: Time.current)
        
        expect(maybe_interview.has_positive_decision?).to be false
        expect(no_interview.has_positive_decision?).to be false
      end
    end

    describe '#has_negative_decision?' do
      it 'returns true for strong_no and no decisions' do
        strong_no_interview = create(:interview, status: 'completed', decision: 'strong_no', completed_at: Time.current)
        no_interview = create(:interview, status: 'completed', decision: 'no', completed_at: Time.current)
        
        expect(strong_no_interview.has_negative_decision?).to be true
        expect(no_interview.has_negative_decision?).to be true
      end

      it 'returns false for other decisions' do
        maybe_interview = create(:interview, status: 'completed', decision: 'maybe', completed_at: Time.current)
        yes_interview = create(:interview, status: 'completed', decision: 'yes', completed_at: Time.current)
        
        expect(maybe_interview.has_negative_decision?).to be false
        expect(yes_interview.has_negative_decision?).to be false
      end
    end

    describe '#has_feedback?' do
      it 'returns true when feedback is present and not just whitespace' do
        interview_with_feedback = create(:interview, feedback: 'Great candidate')
        expect(interview_with_feedback.has_feedback?).to be true
      end

      it 'returns false when feedback is nil or blank' do
        interview_without_feedback = create(:interview, feedback: nil)
        interview_with_blank_feedback = create(:interview, feedback: '   ')
        
        expect(interview_without_feedback.has_feedback?).to be false
        expect(interview_with_blank_feedback.has_feedback?).to be false
      end
    end

    describe '#needs_feedback?' do
      it 'returns true for completed interviews without feedback' do
        interview_needing_feedback = create(:interview, status: 'completed', feedback: nil, completed_at: Time.current)
        expect(interview_needing_feedback.needs_feedback?).to be true
      end

      it 'returns false for completed interviews with feedback' do
        interview_with_feedback = create(:interview, status: 'completed', feedback: 'Good interview', completed_at: Time.current)
        expect(interview_with_feedback.needs_feedback?).to be false
      end

      it 'returns false for non-completed interviews' do
        expect(scheduled_interview.needs_feedback?).to be false
      end
    end
  end

  describe 'time-based methods' do
    around do |example|
      freeze_time { example.run }
    end

    describe '#time_until_interview' do
      it 'calculates hours until interview' do
        interview = create(:interview, scheduled_at: 5.hours.from_now)
        expect(interview.time_until_interview).to eq(5.0)
      end

      it 'returns 0 for past interviews' do
        interview = create(:interview, scheduled_at: 2.hours.ago)
        expect(interview.time_until_interview).to eq(0)
      end
    end

    describe '#days_until_interview' do
      it 'calculates days until interview' do
        interview = create(:interview, scheduled_at: 3.days.from_now)
        expect(interview.days_until_interview).to eq(3)
      end

      it 'returns 0 for past interviews' do
        interview = create(:interview, scheduled_at: 1.day.ago)
        expect(interview.days_until_interview).to eq(0)
      end
    end

    describe '#duration_in_hours' do
      it 'converts minutes to hours' do
        interview = create(:interview, duration_minutes: 90)
        expect(interview.duration_in_hours).to eq(1.5)
      end

      it 'handles exact hours' do
        interview = create(:interview, duration_minutes: 120)
        expect(interview.duration_in_hours).to eq(2.0)
      end
    end

    describe '#scheduled_time_range' do
      it 'formats time range correctly' do
        interview = create(:interview, scheduled_at: Time.current.change(hour: 14, min: 30), duration_minutes: 90)
        expected = "02:30 PM - 04:00 PM"
        expect(interview.scheduled_time_range).to eq(expected)
      end

      it 'returns nil when scheduled_at or duration is missing' do
        interview = create(:interview, scheduled_at: nil)
        expect(interview.scheduled_time_range).to be_nil
        
        interview.update!(scheduled_at: Time.current, duration_minutes: nil)
        expect(interview.scheduled_time_range).to be_nil
      end
    end
  end

  describe 'formatting methods' do
    describe '#interview_type_humanized' do
      let(:type_mappings) do
        {
          'phone' => 'Phone Interview',
          'video' => 'Video Interview',
          'onsite' => 'On-site Interview',
          'technical' => 'Technical Interview',
          'behavioral' => 'Behavioral Interview',
          'panel' => 'Panel Interview'
        }
      end

      it 'formats all interview types correctly' do
        type_mappings.each do |type, expected|
          interview = create(:interview, interview_type: type,
                           location: (type == 'onsite' ? 'Office' : nil),
                           video_link: (type == 'video' ? 'https://zoom.us/j/123' : nil))
          expect(interview.interview_type_humanized).to eq(expected)
        end
      end
    end

    describe '#status_humanized' do
      it 'formats no_show status correctly' do
        interview = create(:interview, status: 'no_show')
        expect(interview.status_humanized).to eq('No Show')
      end

      it 'humanizes other statuses normally' do
        interview = create(:interview, status: 'scheduled')
        expect(interview.status_humanized).to eq('Scheduled')
      end
    end

    describe '#decision_humanized' do
      let(:decision_mappings) do
        {
          'strong_yes' => 'Strong Yes ⭐⭐',
          'yes' => 'Yes ⭐',
          'maybe' => 'Maybe ❓',
          'no' => 'No ❌',
          'strong_no' => 'Strong No ❌❌'
        }
      end

      it 'formats all decision types correctly' do
        decision_mappings.each do |decision, expected|
          interview = create(:interview, status: 'completed', decision: decision, completed_at: Time.current)
          expect(interview.decision_humanized).to eq(expected)
        end
      end

      it 'returns default for nil decision' do
        interview = create(:interview, decision: nil)
        expect(interview.decision_humanized).to eq('No decision yet')
      end
    end

    describe '#rating_display' do
      it 'displays rating with stars' do
        interview = create(:interview, rating: 4)
        expect(interview.rating_display).to eq('4/5 ★★★★☆')
      end

      it 'returns default for unrated' do
        interview = create(:interview, rating: nil)
        expect(interview.rating_display).to eq('Not rated')
      end
    end

    describe '#duration_display' do
      it 'formats minutes correctly' do
        interview = create(:interview, duration_minutes: 45)
        expect(interview.duration_display).to eq('45 min')
      end

      it 'formats exactly 1 hour' do
        interview = create(:interview, duration_minutes: 60)
        expect(interview.duration_display).to eq('1 hour')
      end

      it 'formats hours and minutes' do
        interview = create(:interview, duration_minutes: 90)
        expect(interview.duration_display).to eq('1h 30m')
      end

      it 'formats multiple hours without minutes' do
        interview = create(:interview, duration_minutes: 120)
        expect(interview.duration_display).to eq('2 hours')
      end
    end

    describe '#formatted_scheduled_time' do
      it 'formats full scheduled time' do
        interview = create(:interview, scheduled_at: Time.zone.parse('2023-12-15 14:30:00'))
        expected = 'Friday, December 15, 2023 at 02:30 PM'
        expect(interview.formatted_scheduled_time).to eq(expected)
      end
    end

    describe '#short_scheduled_time' do
      around do |example|
        freeze_time { example.run }
      end

      it 'formats today interviews' do
        interview = create(:interview, scheduled_at: Time.current + 2.hours)
        expected_time = (Time.current + 2.hours).strftime('%I:%M %p')
        expect(interview.short_scheduled_time).to eq("Today at #{expected_time}")
      end

      it 'formats tomorrow interviews' do
        interview = create(:interview, scheduled_at: 1.day.from_now)
        expected_time = 1.day.from_now.strftime('%I:%M %p')
        expect(interview.short_scheduled_time).to eq("Tomorrow at #{expected_time}")
      end

      it 'formats other day interviews' do
        interview = create(:interview, scheduled_at: 2.days.from_now)
        expected = 2.days.from_now.strftime('%m/%d/%Y %I:%M %p')
        expect(interview.short_scheduled_time).to eq(expected)
      end
    end
  end

  describe 'metadata helpers' do
    let(:interview) { create(:interview) }

    describe '#set_metadata' do
      it 'sets metadata key-value pairs' do
        interview.set_metadata(:interview_notes, 'Candidate was well prepared')
        expect(interview.get_metadata(:interview_notes)).to eq('Candidate was well prepared')
      end

      it 'merges with existing metadata' do
        interview.update!(metadata: { 'existing_key' => 'existing_value' })
        interview.set_metadata(:new_key, 'new_value')
        
        expect(interview.get_metadata(:existing_key)).to eq('existing_value')
        expect(interview.get_metadata(:new_key)).to eq('new_value')
      end

      it 'converts keys to strings' do
        interview.set_metadata(:symbol_key, 'symbol_value')
        expect(interview.metadata['symbol_key']).to eq('symbol_value')
      end
    end

    describe '#get_metadata' do
      it 'retrieves metadata values' do
        interview.update!(metadata: { 'test_key' => 'test_value' })
        expect(interview.get_metadata(:test_key)).to eq('test_value')
        expect(interview.get_metadata('test_key')).to eq('test_value')
      end

      it 'returns nil for non-existent keys' do
        expect(interview.get_metadata(:non_existent)).to be_nil
      end
    end
  end

  describe 'class methods' do
    before do
      create(:interview, status: 'scheduled')
      create(:interview, status: 'completed', completed_at: Time.current)
      create(:interview, status: 'completed', rating: 4, completed_at: Time.current)
      create(:interview, status: 'cancelled')
      create(:interview, status: 'no_show')
    end

    describe '.completion_rate' do
      it 'calculates completion rate' do
        # 2 completed out of 5 total = 40%
        expect(Interview.completion_rate).to eq(40.0)
      end

      it 'returns 0 when no interviews' do
        Interview.destroy_all
        expect(Interview.completion_rate).to eq(0)
      end
    end

    describe '.average_rating' do
      it 'calculates average rating of completed interviews' do
        create(:interview, status: 'completed', rating: 2, completed_at: Time.current)
        # (4 + 2) / 2 = 3.0 (ignoring completed interviews without ratings)
        expect(Interview.average_rating).to eq(3.0)
      end

      it 'returns 0 when no rated completed interviews' do
        Interview.where.not(rating: nil).destroy_all
        expect(Interview.average_rating).to eq(0)
      end
    end

    describe '.no_show_rate' do
      it 'calculates no show rate excluding cancelled interviews' do
        # 1 no_show out of 4 non-cancelled = 25%
        expect(Interview.no_show_rate).to eq(25.0)
      end

      it 'returns 0 when no non-cancelled interviews' do
        Interview.where.not(status: 'cancelled').destroy_all
        expect(Interview.no_show_rate).to eq(0)
      end
    end

    describe '.decision_breakdown' do
      before do
        create(:interview, status: 'completed', decision: 'yes', completed_at: Time.current)
        create(:interview, status: 'completed', decision: 'yes', completed_at: Time.current)
        create(:interview, status: 'completed', decision: 'no', completed_at: Time.current)
      end

      it 'groups completed interviews by decision' do
        result = Interview.decision_breakdown
        expect(result['yes']).to eq(2)
        expect(result['no']).to eq(1)
      end
    end

    describe '.type_breakdown' do
      before do
        create(:interview, interview_type: 'phone')
        create(:interview, interview_type: 'phone')
        create(:interview, interview_type: 'video', video_link: 'https://zoom.us/j/123')
      end

      it 'groups interviews by type' do
        result = Interview.type_breakdown
        expect(result['phone']).to be >= 2
        expect(result['video']).to be >= 1
      end
    end

    describe '.average_duration' do
      it 'calculates average duration' do
        # Assuming default factory creates 60-minute interviews
        # The actual average will depend on factory defaults and created interviews
        avg = Interview.average_duration
        expect(avg).to be > 0
        expect(avg).to be_an(Integer)
      end

      it 'returns 0 when no interviews' do
        Interview.destroy_all
        expect(Interview.average_duration).to eq(0)
      end
    end
  end

  describe 'JSONB metadata field' do
    let(:interview) { create(:interview) }

    it 'stores and retrieves complex metadata' do
      metadata = {
        'preparation_materials' => [
          { 'title' => 'Job Description', 'url' => 'https://example.com/jd' },
          { 'title' => 'Company Info', 'url' => 'https://example.com/info' }
        ],
        'technical_requirements' => {
          'languages' => ['Ruby', 'JavaScript'],
          'tools' => ['VS Code', 'Git']
        },
        'accessibility_needs' => ['screen_reader_compatible', 'closed_captions']
      }
      
      interview.update!(metadata: metadata)
      interview.reload
      
      expect(interview.metadata['preparation_materials'].first['title']).to eq('Job Description')
      expect(interview.metadata['technical_requirements']['languages']).to include('Ruby')
      expect(interview.metadata['accessibility_needs']).to include('screen_reader_compatible')
    end

    it 'queries JSONB data' do
      interview.update!(metadata: { 'interview_style' => 'conversational', 'difficulty' => 'medium' })
      other_interview = create(:interview, metadata: { 'interview_style' => 'formal' })
      
      # Query interviews with conversational style
      conversational = Interview.where("metadata->>'interview_style' = ?", 'conversational')
      expect(conversational).to include(interview)
      expect(conversational).not_to include(other_interview)
    end
  end

  describe 'performance considerations' do
    it 'includes associations to prevent N+1 queries' do
      # Test basic query structure
      application = create(:application)
      interviewer = create(:user, company: application.company)
      create_list(:interview, 3, application: application, interviewer: interviewer)

      # Test that scopes work properly
      interviews = Interview.for_application(application).includes(:interviewer, :application)
      expect(interviews.count).to eq(3)
      
      interviews.each do |interview|
        expect(interview.interviewer_full_name).to be_present
        expect(interview.candidate_full_name).to be_present
      end
    end
  end

  # Edge cases and error handling
  describe 'edge cases' do
    it 'handles empty metadata gracefully' do
      interview = create(:interview, metadata: {})
      expect(interview.get_metadata(:non_existent)).to be_nil
      interview.set_metadata(:new_key, 'value')
      expect(interview.get_metadata(:new_key)).to eq('value')
    end

    it 'validates metadata presence even when empty' do
      interview = build(:interview, metadata: nil)
      expect(interview).not_to be_valid
      expect(interview.errors[:metadata]).to include("can't be blank")
    end

    it 'handles very long feedback' do
      long_feedback = 'a' * 2001
      interview = build(:interview, feedback: long_feedback)
      expect(interview).not_to be_valid
      expect(interview.errors[:feedback]).to include('is too long (maximum is 2000 characters)')
    end

    it 'handles timezone considerations' do
      # Test that scheduled_at works correctly across timezones
      interview = create(:interview, scheduled_at: Time.zone.parse('2023-12-15 14:30:00 UTC'))
      expect(interview.scheduled_at.utc?).to be true
    end

    it 'handles concurrent updates gracefully' do
      interview = create(:interview)
      
      # Simulate concurrent updates
      interview1 = Interview.find(interview.id)
      interview2 = Interview.find(interview.id)
      
      interview1.update!(notes: 'First update')
      interview2.update!(rating: 4)
      
      interview.reload
      expect(interview.notes).to eq('First update')
      expect(interview.rating).to eq(4)
    end
  end

  describe 'business logic integration' do
    it 'maintains data consistency with application pipeline' do
      # Test that interview state changes don't break application pipeline integrity
      application = create(:application, status: 'phone_interview')
      interview = create(:interview, application: application, interview_type: 'phone')
      
      # Completing interview should not break application state
      travel_to(interview.scheduled_at + 1.hour) do
        interview.complete!(decision: 'yes', rating: 5)
        application.reload
        # Depending on business rules, application status might advance
        expect(application.status).to be_in(['phone_interview', 'technical_interview', 'final_interview'])
      end
    end

    it 'handles calendar integration fields properly' do
      interview = create(:interview, calendar_event_id: 'cal_event_123')
      expect(interview.calendar_event_id).to eq('cal_event_123')
      
      # Test that calendar fields are queryable
      found_interview = Interview.where(calendar_event_id: 'cal_event_123').first
      expect(found_interview).to eq(interview)
    end
  end
end