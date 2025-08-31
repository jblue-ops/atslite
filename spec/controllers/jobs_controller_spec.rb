# frozen_string_literal: true

RSpec.describe JobsController, type: :controller do
  let(:organization)     { create(:organization)                                                    }
  let(:admin_user)       { create(:user, :admin, organization: organization)                        }
  let(:hiring_manager)   { create(:user, :hiring_manager, organization: organization)               }
  let(:recruiter_user)   { create(:user, :recruiter, organization: organization)                    }
  let(:interviewer_user) { create(:user, :interviewer, organization: organization)                  }
  let(:job)              { create(:job, organization: organization, hiring_manager: hiring_manager) }

  before do
    ActsAsTenant.current_tenant = organization
  end

  describe "GET #index" do
    subject { get :index }

    it_behaves_like "requires authentication"

    context "when user is authenticated" do
      before { sign_in recruiter_user }

      it "returns successful response" do
        subject
        expect(response).to have_http_status(:success)
      end

      it "assigns jobs" do
        create_list(:job, 3, organization: organization)
        subject
        expect(assigns(:jobs)).to be_present
        expect(assigns(:jobs).count).to eq(3)
      end

      context "with search parameters" do
        let!(:rails_job) { create(:job, title: "Rails Developer", organization: organization) }
        let!(:react_job) { create(:job, title: "React Developer", organization: organization) }

        it "filters by search term" do
          get :index, params: { search: "Rails" }
          expect(assigns(:jobs)).to include(rails_job)
          expect(assigns(:jobs)).not_to include(react_job)
        end
      end

      context "with status filter" do
        let!(:published_job) { create(:job, :published, organization: organization) }
        let!(:draft_job) { create(:job, organization: organization) }

        it "filters by status" do
          get :index, params: { status: "published" }
          expect(assigns(:jobs)).to include(published_job)
          expect(assigns(:jobs)).not_to include(draft_job)
        end
      end

      context "with employment type filter" do
        let!(:full_time_job) { create(:job, employment_type: "full_time", organization: organization) }
        let!(:contract_job) { create(:job, employment_type: "contract", organization: organization) }

        it "filters by employment type" do
          get :index, params: { employment_type: "full_time" }
          expect(assigns(:jobs)).to include(full_time_job)
          expect(assigns(:jobs)).not_to include(contract_job)
        end
      end
    end
  end

  describe "GET #show" do
    subject { get :show, params: { id: job.id } }

    it_behaves_like "requires authentication"

    context "when user is authenticated" do
      before { sign_in recruiter_user }

      it "returns successful response" do
        subject
        expect(response).to have_http_status(:success)
      end

      it "assigns the job" do
        subject
        expect(assigns(:job)).to eq(job)
      end

      context "when job belongs to different organization" do
        let(:other_organization) { create(:organization) }
        let(:other_job) { create(:job, organization: other_organization) }

        it "raises not found error" do
          expect do
            get :show, params: { id: other_job.id }
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe "GET #new" do
    subject { get :new }

    it_behaves_like "requires authentication"

    context "when user is authenticated" do
      context "as hiring manager" do
        before { sign_in hiring_manager }

        it "returns successful response" do
          subject
          expect(response).to have_http_status(:success)
        end

        it "assigns new job" do
          subject
          expect(assigns(:job)).to be_a_new(Job)
          expect(assigns(:job).organization).to eq(organization)
          expect(assigns(:job).hiring_manager).to eq(hiring_manager)
        end
      end

      context "as interviewer" do
        before { sign_in interviewer_user }

        it "denies access" do
          subject
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq("You are not authorized to perform this action.")
        end
      end
    end
  end

  describe "POST #create" do
    subject { post :create, params: { job: valid_attributes } }

    let(:valid_attributes) do
      {
        title: "Software Engineer",
        description: "We are looking for a software engineer...",
        location: "San Francisco, CA",
        employment_type: "full_time",
        experience_level: "mid",
        salary_range_min: 100_000,
        salary_range_max: 150_000,
        currency: "USD"
      }
    end

    it_behaves_like "requires authentication"

    context "when user is authenticated as hiring manager" do
      before { sign_in hiring_manager }

      context "with valid parameters" do
        it "creates a new job" do
          expect { subject }.to change(Job, :count).by(1)
        end

        it "assigns the job to current organization" do
          subject
          expect(assigns(:job).organization).to eq(organization)
        end

        it "assigns the current user as hiring_manager" do
          subject
          expect(assigns(:job).hiring_manager).to eq(hiring_manager)
        end

        it "redirects to job show page" do
          subject
          expect(response).to redirect_to(job_path(assigns(:job)))
        end

        it "displays success message" do
          subject
          expect(flash[:notice]).to eq("Job was successfully created.")
        end
      end

      context "with invalid parameters" do
        let(:invalid_attributes) { { title: "", description: "" } }

        it "does not create a job" do
          expect do
            post :create, params: { job: invalid_attributes }
          end.not_to change(Job, :count)
        end

        it "renders new template" do
          post :create, params: { job: invalid_attributes }
          expect(response).to render_template(:new)
        end

        it "assigns validation errors" do
          post :create, params: { job: invalid_attributes }
          expect(assigns(:job).errors).to be_present
        end
      end
    end
  end

  describe "GET #edit" do
    subject { get :edit, params: { id: job.id } }

    it_behaves_like "requires authentication"

    context "when user is authenticated" do
      context "as the job creator" do
        before { sign_in admin_user }

        it "returns successful response" do
          subject
          expect(response).to have_http_status(:success)
        end

        it "assigns the job" do
          subject
          expect(assigns(:job)).to eq(job)
        end
      end

      context "as different user in same company" do
        before { sign_in recruiter_user }

        it "allows editing" do
          subject
          expect(response).to have_http_status(:success)
        end
      end
    end
  end

  describe "PATCH #update" do
    subject { patch :update, params: { id: job.id, job: updated_attributes } }

    let(:updated_attributes) { { title: "Senior Software Engineer" } }

    it_behaves_like "requires authentication"

    context "when user is authenticated" do
      before { sign_in recruiter_user }

      context "with valid parameters" do
        it "updates the job" do
          subject
          job.reload
          expect(job.title).to eq("Senior Software Engineer")
        end

        it "redirects to job show page" do
          subject
          expect(response).to redirect_to(job_path(job))
        end

        it "displays success message" do
          subject
          expect(flash[:notice]).to eq("Job was successfully updated.")
        end

        it "creates audit log entry" do
          expect_audit_log("job.updated", job)
          subject
        end
      end

      context "with invalid parameters" do
        let(:invalid_attributes) { { title: "" } }

        it "does not update the job" do
          original_title = job.title
          patch :update, params: { id: job.id, job: invalid_attributes }
          job.reload
          expect(job.title).to eq(original_title)
        end

        it "renders edit template" do
          patch :update, params: { id: job.id, job: invalid_attributes }
          expect(response).to render_template(:edit)
        end
      end
    end
  end

  describe "DELETE #destroy" do
    subject { delete :destroy, params: { id: job_to_delete.id } }

    let!(:job_to_delete) { create(:job, company: company) }

    it_behaves_like "requires authentication"
    it_behaves_like "requires admin access" do
      subject { delete :destroy, params: { id: job_to_delete.id } }

      before { sign_in recruiter_user }

      let(:job_to_delete) { create(:job, company: company) }
    end

    context "when user is admin" do
      before { sign_in admin_user }

      it "destroys the job" do
        expect { subject }.to change(Job, :count).by(-1)
      end

      it "redirects to jobs index" do
        subject
        expect(response).to redirect_to(jobs_path)
      end

      it "displays success message" do
        subject
        expect(flash[:notice]).to eq("Job was successfully deleted.")
      end

      context "when job has applications" do
        let!(:application) { create(:application, job: job_to_delete) }

        it "does not destroy the job" do
          expect { subject }.not_to change(Job, :count)
        end

        it "displays error message" do
          subject
          expect(flash[:alert]).to include("Cannot delete job with existing applications")
        end
      end
    end
  end

  describe "PATCH #publish" do
    subject { patch :publish, params: { id: draft_job.id } }

    let(:draft_job) { create(:job, organization: organization, hiring_manager: hiring_manager) }

    it_behaves_like "requires authentication"

    context "when user is authenticated as hiring manager" do
      before { sign_in hiring_manager }

      it "publishes the job" do
        expect { subject }.to change { draft_job.reload.status }.from("draft").to("published")
      end

      it "sets published_at timestamp" do
        subject
        draft_job.reload
        expect(draft_job.published_at).to be_present
      end

      it "redirects to job show page" do
        subject
        expect(response).to redirect_to(job_path(draft_job))
      end

      it "displays success message" do
        subject
        expect(flash[:notice]).to eq("Job was successfully published.")
      end

      context "when job cannot be published" do
        let(:invalid_job) { create(:job, title: "", organization: organization, hiring_manager: hiring_manager) }

        it "displays error message" do
          patch :publish, params: { id: invalid_job.id }
          expect(flash[:alert]).to include("Cannot publish job")
        end
      end
    end
  end

  describe "PATCH #close" do
    subject { patch :close, params: { id: published_job.id } }

    let(:published_job) { create(:job, :published, organization: organization, hiring_manager: hiring_manager) }

    it_behaves_like "requires authentication"

    context "when user is authenticated as hiring manager" do
      before { sign_in hiring_manager }

      it "closes the job" do
        expect { subject }.to change { published_job.reload.status }.from("published").to("closed")
      end

      it "redirects to job show page" do
        subject
        expect(response).to redirect_to(job_path(published_job))
      end

      it "displays success message" do
        subject
        expect(flash[:notice]).to eq("Job was successfully closed.")
      end
    end
  end

  describe "PATCH #reopen" do
    subject { patch :reopen, params: { id: closed_job.id } }

    let(:closed_job) { create(:job, :closed, organization: organization, hiring_manager: hiring_manager) }

    it_behaves_like "requires authentication"

    context "when user is authenticated as hiring manager" do
      before { sign_in hiring_manager }

      it "reopens the job" do
        expect { subject }.to change { closed_job.reload.status }.from("closed").to("published")
      end

      it "redirects to job show page" do
        subject
        expect(response).to redirect_to(job_path(closed_job))
      end

      it "displays success message" do
        subject
        expect(flash[:notice]).to eq("Job was successfully reopened.")
      end
    end
  end

  describe "PATCH #archive" do
    subject { patch :archive, params: { id: job.id } }

    it_behaves_like "requires authentication"

    context "when user is authenticated as hiring manager" do
      before { sign_in hiring_manager }

      it "archives the job" do
        expect { subject }.to change { job.reload.status }.to("archived")
      end

      it "redirects to job show page" do
        subject
        expect(response).to redirect_to(job_path(job))
      end

      it "displays success message" do
        subject
        expect(flash[:notice]).to eq("Job was successfully archived.")
      end
    end
  end

  describe "PATCH #unarchive" do
    subject { patch :unarchive, params: { id: archived_job.id } }

    let(:archived_job) { create(:job, :archived, organization: organization, hiring_manager: hiring_manager) }

    it_behaves_like "requires authentication"

    context "when user is authenticated as hiring manager" do
      before { sign_in hiring_manager }

      it "unarchives the job" do
        expect { subject }.to change { archived_job.reload.status }.from("archived").to("draft")
      end

      it "redirects to job show page" do
        subject
        expect(response).to redirect_to(job_path(archived_job))
      end

      it "displays success message" do
        subject
        expect(flash[:notice]).to eq("Job was successfully unarchived.")
      end
    end
  end

  describe "private methods" do
    describe "#job_params" do
      let(:controller_instance) { described_class.new }
      let(:params) do
        ActionController::Parameters.new(
          job: {
            title: "Software Engineer",
            description: "Job description",
            location: "Remote",
            employment_type: "full_time",
            experience_level: "mid",
            salary_range_min: 100_000,
            salary_range_max: 150_000,
            currency: "USD",
            remote_work_allowed: true,
            requirements: "Requirements text",
            qualifications: "Qualifications text",
            benefits: "Benefits text",
            application_instructions: "Instructions",
            department_id: 1,
            expires_at: 30.days.from_now,
            unauthorized_param: "should not be permitted"
          }
        )
      end

      it "permits only allowed parameters" do
        controller_instance.params = params
        permitted_params = controller_instance.send(:job_params)

        expect(permitted_params).to include(
          "title", "description", "location", "employment_type",
          "experience_level", "salary_range_min", "salary_range_max",
          "currency", "remote_work_allowed", "requirements",
          "qualifications", "benefits", "application_instructions",
          "department_id", "expires_at"
        )
        expect(permitted_params).not_to have_key("unauthorized_param")
      end
    end
  end
end
