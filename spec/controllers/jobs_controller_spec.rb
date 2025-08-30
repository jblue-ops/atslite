# frozen_string_literal: true

RSpec.describe JobsController, type: :controller do
  let(:company) { create(:company) }
  let(:admin_user) { create(:user, :admin, company: company) }
  let(:recruiter_user) { create(:user, :recruiter, company: company) }
  let(:regular_user) { create(:user, company: company) }
  let(:job) { create(:job, company: company, posted_by: admin_user) }

  before do
    ActsAsTenant.current_tenant = company
  end

  describe 'GET #index' do
    subject { get :index }

    it_behaves_like 'requires authentication'

    context 'when user is authenticated' do
      before { sign_in_as_recruiter }

      it 'returns successful response' do
        subject
        expect(response).to have_http_status(:success)
      end

      it 'assigns jobs' do
        create_list(:job, 3, company: company)
        subject
        expect(assigns(:jobs)).to be_present
        expect(assigns(:jobs).count).to eq(3)
      end

      it 'paginates results' do
        create_list(:job, 30, company: company)
        subject
        expect(assigns(:jobs).count).to be <= 25 # assuming 25 per page
      end

      context 'with search parameters' do
        let!(:rails_job) { create(:job, title: 'Rails Developer', company: company) }
        let!(:react_job) { create(:job, title: 'React Developer', company: company) }

        it 'filters by search term' do
          get :index, params: { search: 'Rails' }
          expect(assigns(:jobs)).to include(rails_job)
          expect(assigns(:jobs)).not_to include(react_job)
        end
      end

      context 'with status filter' do
        let!(:active_job) { create(:job, :active, company: company) }
        let!(:draft_job) { create(:job, company: company) }

        it 'filters by status' do
          get :index, params: { status: 'active' }
          expect(assigns(:jobs)).to include(active_job)
          expect(assigns(:jobs)).not_to include(draft_job)
        end
      end
    end
  end

  describe 'GET #show' do
    subject { get :show, params: { id: job.id } }

    it_behaves_like 'requires authentication'

    context 'when user is authenticated' do
      before { sign_in recruiter_user }

      it 'returns successful response' do
        subject
        expect(response).to have_http_status(:success)
      end

      it 'assigns the job' do
        subject
        expect(assigns(:job)).to eq(job)
      end

      context 'when job belongs to different company' do
        let(:other_company) { create(:company) }
        let(:other_job) { create(:job, company: other_company) }

        it 'raises not found error' do
          expect {
            get :show, params: { id: other_job.id }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe 'GET #new' do
    subject { get :new }

    it_behaves_like 'requires authentication'

    context 'when user is authenticated' do
      context 'as recruiter' do
        before { sign_in recruiter_user }

        it 'returns successful response' do
          subject
          expect(response).to have_http_status(:success)
        end

        it 'assigns new job' do
          subject
          expect(assigns(:job)).to be_a_new(Job)
          expect(assigns(:job).company).to eq(company)
        end
      end

      context 'as regular user' do
        before { sign_in regular_user }

        it_behaves_like 'requires admin access' do
          subject { get :new }
        end
      end
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        title: 'Software Engineer',
        description: 'We are looking for a software engineer...',
        location: 'San Francisco, CA',
        employment_type: 'full_time',
        experience_level: 'mid',
        salary_min: 100_000,
        salary_max: 150_000
      }
    end

    subject { post :create, params: { job: valid_attributes } }

    it_behaves_like 'requires authentication'

    context 'when user is authenticated as recruiter' do
      before { sign_in recruiter_user }

      context 'with valid parameters' do
        it 'creates a new job' do
          expect { subject }.to change(Job, :count).by(1)
        end

        it 'assigns the job to current company' do
          subject
          expect(assigns(:job).company).to eq(company)
        end

        it 'assigns the current user as posted_by' do
          subject
          expect(assigns(:job).posted_by).to eq(recruiter_user)
        end

        it 'redirects to job show page' do
          subject
          expect(response).to redirect_to(job_path(assigns(:job)))
        end

        it 'displays success message' do
          subject
          expect(flash[:notice]).to eq('Job was successfully created.')
        end

        it 'creates audit log entry' do
          expect_audit_log('job.created')
          subject
        end
      end

      context 'with invalid parameters' do
        let(:invalid_attributes) { { title: '', description: '' } }

        it 'does not create a job' do
          expect {
            post :create, params: { job: invalid_attributes }
          }.not_to change(Job, :count)
        end

        it 'renders new template' do
          post :create, params: { job: invalid_attributes }
          expect(response).to render_template(:new)
        end

        it 'assigns validation errors' do
          post :create, params: { job: invalid_attributes }
          expect(assigns(:job).errors).to be_present
        end
      end
    end
  end

  describe 'GET #edit' do
    subject { get :edit, params: { id: job.id } }

    it_behaves_like 'requires authentication'

    context 'when user is authenticated' do
      context 'as the job creator' do
        before { sign_in admin_user }

        it 'returns successful response' do
          subject
          expect(response).to have_http_status(:success)
        end

        it 'assigns the job' do
          subject
          expect(assigns(:job)).to eq(job)
        end
      end

      context 'as different user in same company' do
        before { sign_in recruiter_user }

        it 'allows editing' do
          subject
          expect(response).to have_http_status(:success)
        end
      end
    end
  end

  describe 'PATCH #update' do
    let(:updated_attributes) { { title: 'Senior Software Engineer' } }
    subject { patch :update, params: { id: job.id, job: updated_attributes } }

    it_behaves_like 'requires authentication'

    context 'when user is authenticated' do
      before { sign_in recruiter_user }

      context 'with valid parameters' do
        it 'updates the job' do
          subject
          job.reload
          expect(job.title).to eq('Senior Software Engineer')
        end

        it 'redirects to job show page' do
          subject
          expect(response).to redirect_to(job_path(job))
        end

        it 'displays success message' do
          subject
          expect(flash[:notice]).to eq('Job was successfully updated.')
        end

        it 'creates audit log entry' do
          expect_audit_log('job.updated', job)
          subject
        end
      end

      context 'with invalid parameters' do
        let(:invalid_attributes) { { title: '' } }

        it 'does not update the job' do
          original_title = job.title
          patch :update, params: { id: job.id, job: invalid_attributes }
          job.reload
          expect(job.title).to eq(original_title)
        end

        it 'renders edit template' do
          patch :update, params: { id: job.id, job: invalid_attributes }
          expect(response).to render_template(:edit)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:job_to_delete) { create(:job, company: company) }
    subject { delete :destroy, params: { id: job_to_delete.id } }

    it_behaves_like 'requires authentication'
    it_behaves_like 'requires admin access' do
      before { sign_in recruiter_user }
      let(:job_to_delete) { create(:job, company: company) }
      subject { delete :destroy, params: { id: job_to_delete.id } }
    end

    context 'when user is admin' do
      before { sign_in admin_user }

      it 'destroys the job' do
        expect { subject }.to change(Job, :count).by(-1)
      end

      it 'redirects to jobs index' do
        subject
        expect(response).to redirect_to(jobs_path)
      end

      it 'displays success message' do
        subject
        expect(flash[:notice]).to eq('Job was successfully deleted.')
      end

      context 'when job has applications' do
        let!(:application) { create(:application, job: job_to_delete) }

        it 'does not destroy the job' do
          expect { subject }.not_to change(Job, :count)
        end

        it 'displays error message' do
          subject
          expect(flash[:alert]).to include('Cannot delete job with existing applications')
        end
      end
    end
  end

  describe 'PATCH #publish' do
    let(:draft_job) { create(:job, company: company) }
    subject { patch :publish, params: { id: draft_job.id } }

    it_behaves_like 'requires authentication'

    context 'when user is authenticated as recruiter' do
      before { sign_in recruiter_user }

      it 'publishes the job' do
        expect { subject }.to change { draft_job.reload.status }.from('draft').to('active')
      end

      it 'sets published_at timestamp' do
        subject
        draft_job.reload
        expect(draft_job.published_at).to be_present
      end

      it 'redirects to job show page' do
        subject
        expect(response).to redirect_to(job_path(draft_job))
      end

      it 'displays success message' do
        subject
        expect(flash[:notice]).to eq('Job was successfully published.')
      end

      context 'when job cannot be published' do
        let(:closed_job) { create(:job, :closed, company: company) }

        it 'does not change job status' do
          expect {
            patch :publish, params: { id: closed_job.id }
          }.not_to change { closed_job.reload.status }
        end

        it 'displays error message' do
          patch :publish, params: { id: closed_job.id }
          expect(flash[:alert]).to include('Cannot publish job')
        end
      end
    end
  end

  describe 'private methods' do
    describe '#job_params' do
      let(:controller_instance) { JobsController.new }
      let(:params) do
        ActionController::Parameters.new(
          job: {
            title: 'Software Engineer',
            description: 'Job description',
            location: 'Remote',
            employment_type: 'full_time',
            experience_level: 'mid',
            salary_min: 100_000,
            salary_max: 150_000,
            unauthorized_param: 'should not be permitted'
          }
        )
      end

      it 'permits only allowed parameters' do
        controller_instance.params = params
        permitted_params = controller_instance.send(:job_params)
        
        expect(permitted_params).to include(
          'title', 'description', 'location', 'employment_type',
          'experience_level', 'salary_min', 'salary_max'
        )
        expect(permitted_params).not_to have_key('unauthorized_param')
      end
    end
  end
end