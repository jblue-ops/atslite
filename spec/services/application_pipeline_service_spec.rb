# frozen_string_literal: true

RSpec.describe ApplicationPipelineService, type: :service do
  let(:company) { create(:company) }
  let(:job) { create(:job, :active, company: company) }
  let(:application) { create(:application, job: job) }
  let(:user) { create(:user, :recruiter, company: company) }
  let(:service) { described_class.new(application, user) }

  before do
    ActsAsTenant.current_tenant = company
  end

  describe '#initialize' do
    it 'sets application and user attributes' do
      expect(service.application).to eq(application)
      expect(service.user).to eq(user)
    end

    it 'raises error with nil application' do
      expect {
        described_class.new(nil, user)
      }.to raise_error(ArgumentError, 'Application cannot be nil')
    end

    it 'raises error with nil user' do
      expect {
        described_class.new(application, nil)
      }.to raise_error(ArgumentError, 'User cannot be nil')
    end
  end

  describe '#advance_to_stage' do
    let(:target_stage) { 'screening' }

    context 'with valid stage transition' do
      it 'advances application to target stage' do
        expect {
          service.advance_to_stage(target_stage)
        }.to change { application.reload.current_stage }.from('applied').to('screening')
      end

      it 'creates stage transition record' do
        expect {
          service.advance_to_stage(target_stage)
        }.to change(StageTransition, :count).by(1)
      end

      it 'sets transition metadata' do
        service.advance_to_stage(target_stage, notes: 'Strong technical background')
        
        transition = application.stage_transitions.last
        expect(transition.from_stage).to eq('applied')
        expect(transition.to_stage).to eq('screening')
        expect(transition.transitioned_by).to eq(user)
        expect(transition.notes).to eq('Strong technical background')
      end

      it 'triggers notification' do
        expect_notification_sent('stage_advanced', application.candidate) do
          service.advance_to_stage(target_stage)
        end
      end

      it 'creates audit log entry' do
        expect_audit_log('application.stage_advanced', application)
        service.advance_to_stage(target_stage)
      end

      it 'returns success result' do
        result = service.advance_to_stage(target_stage)
        expect(result.success?).to be true
        expect(result.data[:application]).to eq(application)
        expect(result.data[:transition]).to be_a(StageTransition)
      end
    end

    context 'with invalid stage transition' do
      let(:invalid_stage) { 'nonexistent_stage' }

      it 'does not change application stage' do
        expect {
          service.advance_to_stage(invalid_stage)
        }.not_to change { application.reload.current_stage }
      end

      it 'does not create transition record' do
        expect {
          service.advance_to_stage(invalid_stage)
        }.not_to change(StageTransition, :count)
      end

      it 'returns failure result' do
        result = service.advance_to_stage(invalid_stage)
        expect(result.failure?).to be true
        expect(result.errors).to include('Invalid stage transition')
      end
    end

    context 'when application is already in target stage' do
      before { application.update!(current_stage: target_stage) }

      it 'does not create duplicate transition' do
        expect {
          service.advance_to_stage(target_stage)
        }.not_to change(StageTransition, :count)
      end

      it 'returns success with no changes' do
        result = service.advance_to_stage(target_stage)
        expect(result.success?).to be true
        expect(result.message).to include('already in stage')
      end
    end

    context 'with stage that requires interview scheduling' do
      let(:interview_stage) { 'technical_interview' }

      it 'creates interview placeholder' do
        expect {
          service.advance_to_stage(interview_stage)
        }.to change(Interview, :count).by(1)

        interview = application.interviews.last
        expect(interview.interview_type).to eq('technical')
        expect(interview.status).to eq('to_be_scheduled')
      end
    end
  end

  describe '#reject_application' do
    let(:rejection_reason) { 'not_qualified' }
    let(:feedback) { 'Candidate lacks required technical skills' }

    context 'with valid rejection' do
      it 'changes application status to rejected' do
        expect {
          service.reject_application(rejection_reason, feedback)
        }.to change { application.reload.current_stage }.to('rejected')
      end

      it 'sets rejection timestamp' do
        service.reject_application(rejection_reason, feedback)
        expect(application.reload.rejected_at).to be_present
      end

      it 'creates rejection record' do
        expect {
          service.reject_application(rejection_reason, feedback)
        }.to change(Rejection, :count).by(1)

        rejection = application.rejection
        expect(rejection.reason).to eq(rejection_reason)
        expect(rejection.feedback).to eq(feedback)
        expect(rejection.rejected_by).to eq(user)
      end

      it 'sends rejection notification' do
        expect_notification_sent('application_rejected', application.candidate) do
          service.reject_application(rejection_reason, feedback)
        end
      end

      it 'creates audit trail' do
        expect_audit_log('application.rejected', application)
        service.reject_application(rejection_reason, feedback)
      end

      it 'cancels upcoming interviews' do
        upcoming_interview = create(:interview, application: application, status: 'scheduled')
        
        service.reject_application(rejection_reason, feedback)
        
        expect(upcoming_interview.reload.status).to eq('cancelled')
      end

      it 'returns success result' do
        result = service.reject_application(rejection_reason, feedback)
        expect(result.success?).to be true
        expect(result.data[:rejection]).to be_a(Rejection)
      end
    end

    context 'with already rejected application' do
      before do
        application.update!(current_stage: 'rejected', rejected_at: 1.day.ago)
      end

      it 'does not create duplicate rejection' do
        expect {
          service.reject_application(rejection_reason, feedback)
        }.not_to change(Rejection, :count)
      end

      it 'returns failure result' do
        result = service.reject_application(rejection_reason, feedback)
        expect(result.failure?).to be true
        expect(result.errors).to include('Application already rejected')
      end
    end
  end

  describe '#bulk_advance' do
    let!(:applications) { create_list(:application, 3, job: job) }
    let(:target_stage) { 'screening' }

    context 'with valid applications' do
      it 'advances all applications to target stage' do
        result = service.bulk_advance(applications.map(&:id), target_stage)
        
        applications.each do |app|
          expect(app.reload.current_stage).to eq(target_stage)
        end
        
        expect(result.success?).to be true
        expect(result.data[:successful_count]).to eq(3)
      end

      it 'creates transition records for all applications' do
        expect {
          service.bulk_advance(applications.map(&:id), target_stage)
        }.to change(StageTransition, :count).by(3)
      end

      it 'sends notifications to all candidates' do
        applications.each do |app|
          expect_notification_sent('stage_advanced', app.candidate) do
            service.bulk_advance(applications.map(&:id), target_stage)
          end
        end
      end
    end

    context 'with mixed valid and invalid applications' do
      let!(:rejected_application) { create(:application, :rejected, job: job) }
      let(:all_application_ids) { (applications + [rejected_application]).map(&:id) }

      it 'processes only valid applications' do
        result = service.bulk_advance(all_application_ids, target_stage)
        
        expect(result.success?).to be true
        expect(result.data[:successful_count]).to eq(3)
        expect(result.data[:failed_count]).to eq(1)
        
        applications.each do |app|
          expect(app.reload.current_stage).to eq(target_stage)
        end
        
        expect(rejected_application.reload.current_stage).to eq('rejected')
      end
    end
  end

  describe '#get_available_stages' do
    context 'for application in applied stage' do
      it 'returns next possible stages' do
        stages = service.get_available_stages
        expect(stages).to include('screening', 'phone_interview')
        expect(stages).not_to include('offer', 'hired')
      end
    end

    context 'for application in final interview stage' do
      before { application.update!(current_stage: 'final_interview') }

      it 'returns offer and rejection stages' do
        stages = service.get_available_stages
        expect(stages).to include('offer', 'rejected')
        expect(stages).not_to include('applied', 'screening')
      end
    end
  end

  describe '#calculate_time_in_stage' do
    let!(:transition) do
      create(:stage_transition,
             application: application,
             from_stage: 'applied',
             to_stage: 'screening',
             transitioned_at: 5.days.ago)
    end

    before { application.update!(current_stage: 'screening') }

    it 'returns time spent in current stage' do
      time_in_stage = service.calculate_time_in_stage
      expect(time_in_stage).to be_within(1.hour).of(5.days)
    end

    it 'returns time for specific stage' do
      time_in_applied = service.calculate_time_in_stage('applied')
      expect(time_in_applied).to be > 0
    end
  end

  describe '#generate_pipeline_report' do
    let!(:applications) do
      [
        create(:application, job: job, current_stage: 'applied'),
        create(:application, job: job, current_stage: 'screening'),
        create(:application, job: job, current_stage: 'screening'),
        create(:application, job: job, current_stage: 'offer'),
        create(:application, job: job, current_stage: 'rejected')
      ]
    end

    it 'returns stage distribution' do
      report = service.generate_pipeline_report
      
      expect(report[:stage_counts]).to eq({
        'applied' => 1,
        'screening' => 2,
        'offer' => 1,
        'rejected' => 1
      })
    end

    it 'calculates conversion rates' do
      report = service.generate_pipeline_report
      
      expect(report[:conversion_rates]['screening']).to eq(40.0) # 2 out of 5
      expect(report[:conversion_rates]['offer']).to eq(20.0)     # 1 out of 5
    end

    it 'includes average time per stage' do
      report = service.generate_pipeline_report
      expect(report[:average_time_per_stage]).to be_a(Hash)
    end
  end

  describe 'error handling' do
    context 'when database error occurs' do
      before do
        allow(application).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
      end

      it 'handles and returns appropriate error' do
        result = service.advance_to_stage('screening')
        expect(result.failure?).to be true
        expect(result.errors).to include('Failed to update application')
      end
    end

    context 'when notification service fails' do
      before do
        allow(NotificationService).to receive(:send_notification).and_raise(StandardError, 'Email service down')
      end

      it 'continues processing but logs error' do
        expect(Rails.logger).to receive(:error).with(/Failed to send notification/)
        
        result = service.advance_to_stage('screening')
        expect(result.success?).to be true # Still succeeds despite notification failure
      end
    end
  end

  describe 'integration with job pipeline configuration' do
    let(:custom_job) { create(:job, :with_custom_pipeline, company: company) }
    let(:custom_application) { create(:application, job: custom_job) }
    let(:custom_service) { described_class.new(custom_application, user) }

    it 'respects job-specific pipeline stages' do
      available_stages = custom_service.get_available_stages
      expect(available_stages).to include('coding_challenge')
      expect(available_stages).not_to include('phone_interview')
    end

    it 'validates transitions based on job pipeline' do
      result = custom_service.advance_to_stage('system_design')
      expect(result.failure?).to be true
      expect(result.errors).to include('Invalid stage transition')
    end
  end
end