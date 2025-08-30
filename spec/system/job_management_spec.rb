# frozen_string_literal: true

RSpec.describe 'Job Management', type: :system, js: true do
  let(:company) { create(:company) }
  let(:admin_user) { create(:user, :admin, company: company) }
  let(:recruiter_user) { create(:user, :recruiter, company: company) }

  before do
    ActsAsTenant.current_tenant = company
  end

  describe 'Job listing page' do
    let!(:active_job) { create(:job, :active, title: 'Senior Rails Developer', company: company) }
    let!(:draft_job) { create(:job, title: 'Frontend Developer', company: company) }
    let!(:closed_job) { create(:job, :closed, title: 'Product Manager', company: company) }

    context 'when user is authenticated', authenticated: true do
      before do
        sign_in_user(recruiter_user)
        visit jobs_path
      end

      it 'displays all jobs' do
        expect(page).to have_content('Senior Rails Developer')
        expect(page).to have_content('Frontend Developer')
        expect(page).to have_content('Product Manager')
      end

      it 'shows job status badges' do
        expect(page).to have_css('.badge.active', text: 'Active')
        expect(page).to have_css('.badge.draft', text: 'Draft')
        expect(page).to have_css('.badge.closed', text: 'Closed')
      end

      it 'allows filtering by status' do
        select 'Active', from: 'Status'
        click_button 'Filter'

        expect(page).to have_content('Senior Rails Developer')
        expect(page).not_to have_content('Frontend Developer')
        expect(page).not_to have_content('Product Manager')
      end

      it 'allows searching by title' do
        fill_in 'Search', with: 'Rails'
        click_button 'Search'

        expect(page).to have_content('Senior Rails Developer')
        expect(page).not_to have_content('Frontend Developer')
        expect(page).not_to have_content('Product Manager')
      end

      it 'shows create new job button for authorized users' do
        expect(page).to have_link('Create New Job', href: new_job_path)
      end

      it 'displays job statistics' do
        expect(page).to have_content('3 total jobs')
        expect(page).to have_content('1 active')
        expect(page).to have_content('1 draft')
      end
    end

    context 'when user is not authenticated' do
      before { visit jobs_path }

      it_behaves_like 'displays flash messages'
      
      it 'redirects to sign in page' do
        expect_to_be_redirected_to_sign_in
      end
    end
  end

  describe 'Creating a new job' do
    context 'as a recruiter', authenticated: true do
      before do
        sign_in_user(recruiter_user)
        visit new_job_path
      end

      it_behaves_like 'has accessible form'

      it 'displays the job creation form' do
        expect(page).to have_field('Title')
        expect(page).to have_field('Description')
        expect(page).to have_field('Location')
        expect(page).to have_select('Employment Type')
        expect(page).to have_select('Experience Level')
        expect(page).to have_field('Minimum Salary')
        expect(page).to have_field('Maximum Salary')
      end

      it 'creates a job successfully with valid data' do
        fill_in 'Title', with: 'Senior Ruby Developer'
        fill_in 'Description', with: 'We are looking for an experienced Ruby developer to join our team.'
        fill_in 'Location', with: 'San Francisco, CA'
        select 'Full Time', from: 'Employment Type'
        select 'Senior', from: 'Experience Level'
        fill_in 'Minimum Salary', with: '120000'
        fill_in 'Maximum Salary', with: '160000'
        check 'Remote Work OK'

        click_button 'Create Job'

        expect(page).to have_content('Job was successfully created')
        expect(page).to have_content('Senior Ruby Developer')
        expect(current_path).to match(/\/jobs\/\d+/)
      end

      it 'shows validation errors for invalid data' do
        fill_in 'Title', with: ''
        click_button 'Create Job'

        expect(page).to have_content("Title can't be blank")
        expect(current_path).to eq(jobs_path) # stays on form
      end

      it 'pre-fills company information' do
        expect(page).to have_content(company.name)
      end

      it 'allows saving as draft or publishing' do
        fill_in 'Title', with: 'Test Job'
        fill_in 'Description', with: 'Test description'
        fill_in 'Location', with: 'Remote'
        select 'Full Time', from: 'Employment Type'
        select 'Mid', from: 'Experience Level'

        # Save as draft
        click_button 'Save as Draft'
        expect(page).to have_content('Draft')

        # Publish
        click_link 'Publish'
        expect(page).to have_content('Active')
      end
    end
  end

  describe 'Editing a job' do
    let!(:job) { create(:job, title: 'Original Title', company: company, posted_by: admin_user) }

    context 'as authorized user', authenticated: true do
      before do
        sign_in_user(admin_user)
        visit edit_job_path(job)
      end

      it 'pre-fills the form with existing data' do
        expect(page).to have_field('Title', with: 'Original Title')
        expect(page).to have_field('Description', with: job.description)
      end

      it 'updates the job successfully' do
        fill_in 'Title', with: 'Updated Title'
        click_button 'Update Job'

        expect(page).to have_content('Job was successfully updated')
        expect(page).to have_content('Updated Title')
      end

      it 'shows validation errors for invalid updates' do
        fill_in 'Title', with: ''
        click_button 'Update Job'

        expect(page).to have_content("Title can't be blank")
      end

      it 'allows changing job status' do
        select 'Active', from: 'Status'
        click_button 'Update Job'

        expect(page).to have_css('.badge.active')
      end
    end
  end

  describe 'Job details page' do
    let!(:job) { create(:job, :active, :with_applications, company: company, applications_count: 5) }
    let!(:interview) { create(:interview, application: job.applications.first) }

    context 'when viewing job details', authenticated: true do
      before do
        sign_in_user(recruiter_user)
        visit job_path(job)
      end

      it 'displays job information' do
        expect(page).to have_content(job.title)
        expect(page).to have_content(job.description)
        expect(page).to have_content(job.location)
        expect(page).to have_content(job.salary_range)
      end

      it 'shows application statistics' do
        expect(page).to have_content('5 Applications')
        expect(page).to have_content('1 Interview Scheduled')
      end

      it 'displays action buttons for authorized users' do
        expect(page).to have_link('Edit Job')
        expect(page).to have_link('View Applications')
        expect(page).to have_button('Close Job')
      end

      it 'allows job status changes' do
        click_button 'Pause Job'
        
        expect(page).to have_content('Job was successfully paused')
        expect(page).to have_css('.badge.paused')
      end

      it 'shows pipeline stages' do
        job.pipeline_stages.each do |stage|
          expect(page).to have_content(stage.name)
        end
      end

      it 'displays recent activity' do
        expect(page).to have_content('Recent Activity')
      end
    end
  end

  describe 'Job search and filtering' do
    let!(:rails_job) { create(:job, :active, title: 'Rails Developer', location: 'San Francisco', company: company) }
    let!(:react_job) { create(:job, :active, title: 'React Developer', location: 'Remote', company: company) }
    let!(:senior_job) { create(:job, :active, :senior_role, title: 'Senior Engineer', company: company) }

    context 'when searching and filtering', authenticated: true do
      before do
        sign_in_user(recruiter_user)
        visit jobs_path
      end

      it 'searches by job title' do
        fill_in 'Search', with: 'Rails'
        click_button 'Search'

        expect(page).to have_content('Rails Developer')
        expect(page).not_to have_content('React Developer')
      end

      it 'filters by location' do
        select 'Remote', from: 'Location'
        click_button 'Filter'

        expect(page).to have_content('React Developer')
        expect(page).not_to have_content('Rails Developer')
      end

      it 'filters by experience level' do
        select 'Senior', from: 'Experience Level'
        click_button 'Filter'

        expect(page).to have_content('Senior Engineer')
        expect(page).not_to have_content('Rails Developer')
      end

      it 'combines multiple filters' do
        fill_in 'Search', with: 'Developer'
        select 'Active', from: 'Status'
        click_button 'Filter'

        expect(page).to have_content('Rails Developer')
        expect(page).to have_content('React Developer')
        expect(page).not_to have_content('Senior Engineer')
      end

      it 'shows no results message when no jobs match' do
        fill_in 'Search', with: 'Nonexistent Job'
        click_button 'Search'

        expect(page).to have_content('No jobs found matching your criteria')
      end
    end
  end

  describe 'Bulk operations' do
    let!(:jobs) { create_list(:job, 3, company: company) }

    context 'as admin user', admin: true do
      before do
        sign_in_admin(admin_user)
        visit jobs_path
      end

      it 'allows selecting multiple jobs' do
        jobs.each do |job|
          check "job_#{job.id}"
        end

        expect(page).to have_button('Bulk Actions')
      end

      it 'can bulk publish jobs' do
        jobs.each { |job| check "job_#{job.id}" }
        
        select 'Publish Selected', from: 'bulk_action'
        click_button 'Apply'

        expect(page).to have_content('3 jobs were successfully published')
        
        jobs.each do |job|
          expect(page).to have_css(".job-#{job.id} .badge.active")
        end
      end

      it 'can bulk close jobs' do
        published_jobs = create_list(:job, :active, 2, company: company)
        visit jobs_path

        published_jobs.each { |job| check "job_#{job.id}" }
        
        select 'Close Selected', from: 'bulk_action'
        click_button 'Apply'

        expect(page).to have_content('2 jobs were successfully closed')
      end
    end
  end

  describe 'Real-time updates' do
    let!(:job) { create(:job, :active, company: company) }

    context 'when viewing job details', authenticated: true, js: true do
      before do
        sign_in_user(recruiter_user)
        visit job_path(job)
      end

      xit 'updates application count in real-time' do
        # Simulate another user creating an application
        using_session('other_user') do
          candidate = create(:candidate)
          create(:application, job: job, candidate: candidate)
        end

        # Wait for real-time update
        expect(page).to have_content('1 Application', wait: 5)
      end
    end
  end

  describe 'Mobile responsiveness' do
    let!(:job) { create(:job, :active, company: company) }

    context 'on mobile device', authenticated: true do
      before do
        page.current_window.resize_to(375, 812) # iPhone X dimensions
        sign_in_user(recruiter_user)
        visit jobs_path
      end

      after do
        page.current_window.resize_to(1400, 1400) # Reset to default
      end

      it 'displays mobile-friendly navigation' do
        expect(page).to have_css('.mobile-menu-toggle')
      end

      it 'shows condensed job cards' do
        expect(page).to have_css('.job-card-mobile')
      end

      it 'allows swiping through job stages on detail page' do
        visit job_path(job)
        expect(page).to have_css('.pipeline-stages-mobile')
      end
    end
  end
end