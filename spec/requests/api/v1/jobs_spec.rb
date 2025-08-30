# frozen_string_literal: true

RSpec.describe 'API V1 Jobs', type: :request do
  let(:company) { create(:company) }
  let(:admin_user) { create(:user, :admin, company: company) }
  let(:recruiter_user) { create(:user, :recruiter, company: company) }
  let(:api_headers) { json_headers(admin_user) }

  before do
    ActsAsTenant.current_tenant = company
  end

  describe 'GET /api/v1/jobs' do
    let!(:active_jobs) { create_list(:job, :active, 3, company: company) }
    let!(:draft_jobs) { create_list(:job, 2, company: company) }
    let!(:closed_job) { create(:job, :closed, company: company) }

    context 'with valid authentication' do
      it 'returns all jobs for the company' do
        get_json('/api/v1/jobs', user: admin_user)
        
        expect_successful_json_response
        expect_paginated_response
        expect(json_response['data'].length).to eq(6)
      end

      it 'includes job attributes' do
        get_json('/api/v1/jobs', user: admin_user)
        
        job_data = json_response['data'].first
        expect(job_data).to include(
          'id', 'title', 'description', 'location', 'employment_type',
          'experience_level', 'salary_min', 'salary_max', 'status',
          'created_at', 'updated_at'
        )
      end

      it 'includes nested company information' do
        get_json('/api/v1/jobs', user: admin_user)
        
        job_data = json_response['data'].first
        expect(job_data['company']).to include('id', 'name', 'domain')
      end

      it 'filters by status parameter' do
        get_json('/api/v1/jobs', params: { status: 'active' }, user: admin_user)
        
        expect(json_response['data'].length).to eq(3)
        json_response['data'].each do |job|
          expect(job['status']).to eq('active')
        end
      end

      it 'searches by title' do
        searchable_job = create(:job, :active, title: 'Senior Ruby Developer', company: company)
        
        get_json('/api/v1/jobs', params: { search: 'Ruby' }, user: admin_user)
        
        expect(json_response['data'].length).to eq(1)
        expect(json_response['data'].first['id']).to eq(searchable_job.id)
      end

      it 'filters by experience level' do
        senior_job = create(:job, :senior_role, :active, company: company)
        
        get_json('/api/v1/jobs', params: { experience_level: 'senior' }, user: admin_user)
        
        matching_jobs = json_response['data'].select { |job| job['experience_level'] == 'senior' }
        expect(matching_jobs).not_to be_empty
      end

      it 'supports pagination' do
        get_json('/api/v1/jobs', params: { page: 1, per_page: 2 }, user: admin_user)
        
        expect_paginated_response
        expect(json_response['data'].length).to eq(2)
        expect(json_response['pagination']['per_page']).to eq(2)
      end

      it 'includes application counts' do
        job_with_apps = active_jobs.first
        create_list(:application, 3, job: job_with_apps)
        
        get_json('/api/v1/jobs', user: admin_user)
        
        job_data = json_response['data'].find { |j| j['id'] == job_with_apps.id }
        expect(job_data['applications_count']).to eq(3)
      end
    end

    context 'without authentication' do
      it 'returns unauthorized error' do
        get '/api/v1/jobs', headers: json_headers
        expect_unauthorized_response
      end
    end

    context 'with user from different company' do
      let(:other_company) { create(:company) }
      let(:other_user) { create(:user, company: other_company) }

      it 'returns empty results' do
        get_json('/api/v1/jobs', user: other_user)
        
        expect_successful_json_response
        expect(json_response['data']).to be_empty
      end
    end
  end

  describe 'GET /api/v1/jobs/:id' do
    let(:job) { create(:job, :active, :with_applications, company: company, applications_count: 5) }

    context 'with valid authentication' do
      it 'returns job details' do
        get_json("/api/v1/jobs/#{job.id}", user: admin_user)
        expect_job_response(job)
      end

      it 'includes detailed associations' do
        get_json("/api/v1/jobs/#{job.id}", user: admin_user)
        
        expect(json_response).to have_key('applications')
        expect(json_response).to have_key('pipeline_stages')
        expect(json_response['pipeline_stages']).to be_an(Array)
      end

      it 'includes job statistics' do
        get_json("/api/v1/jobs/#{job.id}", user: admin_user)
        
        expect(json_response['stats']).to include(
          'total_applications',
          'applications_by_stage',
          'recent_activity_count'
        )
      end

      context 'when job does not exist' do
        it 'returns not found error' do
          get_json('/api/v1/jobs/999999', user: admin_user)
          expect_not_found_response
        end
      end

      context 'when job belongs to different company' do
        let(:other_job) { create(:job, company: create(:company)) }

        it 'returns not found error' do
          get_json("/api/v1/jobs/#{other_job.id}", user: admin_user)
          expect_not_found_response
        end
      end
    end
  end

  describe 'POST /api/v1/jobs' do
    let(:valid_attributes) do
      {
        title: 'Senior Software Engineer',
        description: 'We are looking for a senior software engineer to join our team.',
        requirements: 'Strong Ruby and Rails experience required.',
        location: 'San Francisco, CA',
        employment_type: 'full_time',
        experience_level: 'senior',
        salary_min: 120_000,
        salary_max: 160_000,
        salary_currency: 'USD',
        remote_ok: true,
        department: 'Engineering'
      }
    end

    context 'with valid authentication and data' do
      it 'creates a new job' do
        expect {
          post_json('/api/v1/jobs', params: { job: valid_attributes }, user: admin_user)
        }.to change(Job, :count).by(1)
      end

      it 'returns created job' do
        post_json('/api/v1/jobs', params: { job: valid_attributes }, user: admin_user)
        
        expect_created_json_response
        expect(json_response['title']).to eq('Senior Software Engineer')
        expect(json_response['company_id']).to eq(company.id)
        expect(json_response['posted_by_id']).to eq(admin_user.id)
      end

      it 'sets default status to draft' do
        post_json('/api/v1/jobs', params: { job: valid_attributes }, user: admin_user)
        
        expect(json_response['status']).to eq('draft')
      end

      it 'creates default pipeline stages' do
        post_json('/api/v1/jobs', params: { job: valid_attributes }, user: admin_user)
        
        job = Job.find(json_response['id'])
        expect(job.pipeline_stages).to be_present
      end

      it 'creates audit log entry' do
        expect {
          post_json('/api/v1/jobs', params: { job: valid_attributes }, user: admin_user)
        }.to change(PublicActivity::Activity, :count).by(1)
      end
    end

    context 'with invalid data' do
      let(:invalid_attributes) { { title: '', description: '' } }

      it 'does not create job' do
        expect {
          post_json('/api/v1/jobs', params: { job: invalid_attributes }, user: admin_user)
        }.not_to change(Job, :count)
      end

      it 'returns validation errors' do
        post_json('/api/v1/jobs', params: { job: invalid_attributes }, user: admin_user)
        
        expect_error_json_response
        expect_validation_errors('title', 'description')
      end
    end

    context 'as recruiter user' do
      it 'allows job creation' do
        expect {
          post_json('/api/v1/jobs', params: { job: valid_attributes }, user: recruiter_user)
        }.to change(Job, :count).by(1)
      end
    end

    context 'as regular user' do
      let(:regular_user) { create(:user, company: company) }

      it 'denies access' do
        post_json('/api/v1/jobs', params: { job: valid_attributes }, user: regular_user)
        expect_forbidden_response
      end
    end
  end

  describe 'PATCH /api/v1/jobs/:id' do
    let(:job) { create(:job, company: company, posted_by: admin_user) }
    let(:update_attributes) { { title: 'Updated Job Title', salary_max: 180_000 } }

    context 'with valid authentication and data' do
      it 'updates the job' do
        patch_json("/api/v1/jobs/#{job.id}", params: { job: update_attributes }, user: admin_user)
        
        expect_successful_json_response
        job.reload
        expect(job.title).to eq('Updated Job Title')
        expect(job.salary_max).to eq(180_000)
      end

      it 'returns updated job data' do
        patch_json("/api/v1/jobs/#{job.id}", params: { job: update_attributes }, user: admin_user)
        
        expect(json_response['title']).to eq('Updated Job Title')
        expect(json_response['salary_max']).to eq(180_000)
      end

      it 'creates audit log entry' do
        expect {
          patch_json("/api/v1/jobs/#{job.id}", params: { job: update_attributes }, user: admin_user)
        }.to change(PublicActivity::Activity, :count).by(1)
      end
    end

    context 'with invalid data' do
      let(:invalid_attributes) { { title: '', salary_min: -1000 } }

      it 'does not update job' do
        original_title = job.title
        patch_json("/api/v1/jobs/#{job.id}", params: { job: invalid_attributes }, user: admin_user)
        
        job.reload
        expect(job.title).to eq(original_title)
      end

      it 'returns validation errors' do
        patch_json("/api/v1/jobs/#{job.id}", params: { job: invalid_attributes }, user: admin_user)
        expect_error_json_response
        expect_validation_errors('title', 'salary_min')
      end
    end
  end

  describe 'DELETE /api/v1/jobs/:id' do
    let!(:job) { create(:job, company: company) }

    context 'with admin authentication' do
      it 'deletes the job' do
        expect {
          delete_json("/api/v1/jobs/#{job.id}", user: admin_user)
        }.to change(Job, :count).by(-1)
      end

      it 'returns success response' do
        delete_json("/api/v1/jobs/#{job.id}", user: admin_user)
        expect(response).to have_http_status(:no_content)
      end

      context 'when job has applications' do
        let!(:application) { create(:application, job: job) }

        it 'does not delete job' do
          expect {
            delete_json("/api/v1/jobs/#{job.id}", user: admin_user)
          }.not_to change(Job, :count)
        end

        it 'returns error response' do
          delete_json("/api/v1/jobs/#{job.id}", user: admin_user)
          
          expect_error_json_response(:unprocessable_entity)
          expect(json_response['errors']).to include('Cannot delete job with applications')
        end
      end
    end

    context 'with recruiter authentication' do
      it 'denies access' do
        delete_json("/api/v1/jobs/#{job.id}", user: recruiter_user)
        expect_forbidden_response
      end
    end
  end

  describe 'POST /api/v1/jobs/:id/publish' do
    let(:draft_job) { create(:job, company: company) }

    context 'with valid authentication' do
      it 'publishes the job' do
        post_json("/api/v1/jobs/#{draft_job.id}/publish", user: admin_user)
        
        expect_successful_json_response
        draft_job.reload
        expect(draft_job.status).to eq('active')
        expect(draft_job.published_at).to be_present
      end

      it 'returns updated job data' do
        post_json("/api/v1/jobs/#{draft_job.id}/publish", user: admin_user)
        
        expect(json_response['status']).to eq('active')
        expect(json_response['published_at']).to be_present
      end

      context 'when job cannot be published' do
        let(:closed_job) { create(:job, :closed, company: company) }

        it 'returns error' do
          post_json("/api/v1/jobs/#{closed_job.id}/publish", user: admin_user)
          
          expect_error_json_response(:unprocessable_entity)
          expect(json_response['errors']).to include('Cannot publish closed job')
        end
      end
    end
  end

  describe 'POST /api/v1/jobs/:id/close' do
    let(:active_job) { create(:job, :active, company: company) }

    context 'with admin authentication' do
      it 'closes the job' do
        post_json("/api/v1/jobs/#{active_job.id}/close", user: admin_user)
        
        expect_successful_json_response
        active_job.reload
        expect(active_job.status).to eq('closed')
        expect(active_job.closed_at).to be_present
      end

      it 'notifies applicants' do
        application = create(:application, job: active_job)
        
        expect {
          post_json("/api/v1/jobs/#{active_job.id}/close", user: admin_user)
        }.to change { application.candidate.notifications.count }.by(1)
      end
    end

    context 'with recruiter authentication' do
      it 'denies access for job closing' do
        post_json("/api/v1/jobs/#{active_job.id}/close", user: recruiter_user)
        expect_forbidden_response
      end
    end
  end

  describe 'GET /api/v1/jobs/:id/analytics' do
    let(:job) { create(:job, :active, :with_applications, company: company, applications_count: 10) }

    before do
      # Create applications in different stages
      job.applications[0..2].each { |app| app.update!(current_stage: 'screening') }
      job.applications[3..4].each { |app| app.update!(current_stage: 'interview') }
      job.applications[5].update!(current_stage: 'offer')
      job.applications[6..8].each { |app| app.update!(current_stage: 'rejected') }
    end

    context 'with valid authentication' do
      it 'returns job analytics data' do
        get_json("/api/v1/jobs/#{job.id}/analytics", user: admin_user)
        
        expect_successful_json_response
        expect(json_response).to have_key('applications_by_stage')
        expect(json_response).to have_key('conversion_rates')
        expect(json_response).to have_key('time_metrics')
      end

      it 'includes stage distribution' do
        get_json("/api/v1/jobs/#{job.id}/analytics", user: admin_user)
        
        stage_data = json_response['applications_by_stage']
        expect(stage_data['applied']).to eq(1)
        expect(stage_data['screening']).to eq(3)
        expect(stage_data['interview']).to eq(2)
        expect(stage_data['offer']).to eq(1)
        expect(stage_data['rejected']).to eq(3)
      end

      it 'calculates conversion rates' do
        get_json("/api/v1/jobs/#{job.id}/analytics", user: admin_user)
        
        conversion_rates = json_response['conversion_rates']
        expect(conversion_rates['screening_to_interview']).to be_a(Numeric)
        expect(conversion_rates['interview_to_offer']).to be_a(Numeric)
      end

      it 'includes time metrics' do
        get_json("/api/v1/jobs/#{job.id}/analytics", user: admin_user)
        
        time_metrics = json_response['time_metrics']
        expect(time_metrics).to have_key('average_time_to_hire')
        expect(time_metrics).to have_key('average_time_per_stage')
      end
    end
  end

  describe 'rate limiting', :external_api do
    let(:job) { create(:job, company: company) }

    it 'limits requests per minute' do
      61.times do
        get_json("/api/v1/jobs/#{job.id}", user: admin_user)
      end
      
      expect_rate_limited_response
    end
  end

  describe 'API versioning' do
    let(:job) { create(:job, :active, company: company) }

    context 'with Accept header' do
      it 'respects API version in Accept header' do
        headers = json_headers(admin_user).merge('Accept' => 'application/vnd.ats.v1+json')
        get "/api/v1/jobs/#{job.id}", headers: headers
        
        expect_successful_json_response
        expect(response.headers['API-Version']).to eq('v1')
      end
    end
  end
end