# frozen_string_literal: true

RSpec.describe Job, type: :model do
  subject(:job) { build(:job) }

  describe 'associations' do
    it { is_expected.to belong_to(:company) }
    it { is_expected.to belong_to(:posted_by).class_name('User') }
    it { is_expected.to have_many(:applications).dependent(:destroy) }
    it { is_expected.to have_many(:candidates).through(:applications) }
    it { is_expected.to have_many(:pipeline_stages).dependent(:destroy) }
    it { is_expected.to have_many(:job_postings).dependent(:destroy) }
  end

  describe 'validations' do
    it_behaves_like 'has required fields', :title, :description, :location, :employment_type
    it_behaves_like 'belongs to company'

    it { is_expected.to validate_presence_of(:experience_level) }
    it { is_expected.to validate_inclusion_of(:employment_type).in_array(%w[full_time part_time contract internship]) }
    it { is_expected.to validate_inclusion_of(:experience_level).in_array(%w[entry mid senior lead executive]) }
    
    context 'salary validations' do
      it 'validates salary_min is less than salary_max' do
        job.salary_min = 100_000
        job.salary_max = 80_000
        expect(job).not_to be_valid
        expect(job.errors[:salary_max]).to include('must be greater than minimum salary')
      end
      
      it 'allows nil salary values' do
        job.salary_min = nil
        job.salary_max = nil
        expect(job).to be_valid
      end
      
      it 'validates positive salary values' do
        job.salary_min = -1000
        expect(job).not_to be_valid
        expect(job.errors[:salary_min]).to include('must be greater than 0')
      end
    end
  end

  describe 'scopes' do
    let!(:active_job) { create(:job, :active) }
    let!(:draft_job) { create(:job) }
    let!(:closed_job) { create(:job, :closed) }
    let!(:remote_job) { create(:job, :remote) }

    describe '.active' do
      it 'returns only active jobs' do
        expect(Job.active).to contain_exactly(active_job)
      end
    end

    describe '.remote' do
      it 'returns jobs that allow remote work' do
        expect(Job.remote).to include(remote_job)
      end
    end

    describe '.by_experience_level' do
      let!(:senior_job) { create(:job, :senior_role) }
      
      it 'filters by experience level' do
        expect(Job.by_experience_level('senior')).to include(senior_job)
      end
    end
  end

  describe 'state machine' do
    it_behaves_like 'a job with states'
    
    describe 'state transitions' do
      it 'starts in draft state' do
        expect(job.status).to eq('draft')
      end
      
      it 'can be published' do
        expect { job.publish! }.to change(job, :status).from('draft').to('active')
        expect(job.published_at).to be_present
      end
      
      it 'can be closed' do
        job.publish!
        expect { job.close! }.to change(job, :status).from('active').to('closed')
        expect(job.closed_at).to be_present
      end
      
      it 'can be paused' do
        job.publish!
        expect { job.pause! }.to change(job, :status).from('active').to('paused')
        expect(job.paused_at).to be_present
      end
      
      it 'cannot transition from closed to active' do
        job.publish!
        job.close!
        expect { job.publish! }.to raise_error(StateMachines::InvalidTransition)
      end
    end
  end

  describe 'callbacks' do
    describe 'after_create' do
      it 'creates default pipeline stages' do
        job = create(:job)
        expect(job.pipeline_stages.count).to be > 0
        expect(job.pipeline_stages.pluck(:name)).to include('Applied', 'Phone Screen', 'Offer')
      end
    end
    
    describe 'before_save' do
      it 'sets published_at when publishing' do
        job.status = 'active'
        job.save!
        expect(job.published_at).to be_within(1.second).of(Time.current)
      end
    end
  end

  describe 'instance methods' do
    describe '#salary_range' do
      context 'when both salary values are present' do
        it 'returns formatted salary range' do
          job.salary_min = 80_000
          job.salary_max = 120_000
          job.salary_currency = 'USD'
          expect(job.salary_range).to eq('$80,000 - $120,000')
        end
      end
      
      context 'when salary values are not present' do
        it 'returns competitive message' do
          job.salary_min = nil
          job.salary_max = nil
          expect(job.salary_range).to eq('Competitive')
        end
      end
    end
    
    describe '#applications_count' do
      let!(:job) { create(:job, :active) }
      
      it 'returns the number of applications' do
        create_list(:application, 3, job: job)
        expect(job.applications_count).to eq(3)
      end
    end
    
    describe '#days_since_posted' do
      let!(:job) { create(:job, :active, published_at: 5.days.ago) }
      
      it 'returns days since job was published' do
        expect(job.days_since_posted).to eq(5)
      end
    end
    
    describe '#remote?' do
      it 'returns true for remote jobs' do
        job.remote_ok = true
        expect(job).to be_remote
      end
      
      it 'returns false for non-remote jobs' do
        job.remote_ok = false
        expect(job).not_to be_remote
      end
    end
  end

  describe 'search functionality' do
    let!(:rails_job) { create(:job, :active, title: 'Rails Developer', description: 'Ruby on Rails experience required') }
    let!(:react_job) { create(:job, :active, title: 'React Developer', description: 'JavaScript and React skills needed') }
    
    describe '.search' do
      it 'finds jobs by title' do
        results = Job.search('Rails')
        expect(results).to include(rails_job)
        expect(results).not_to include(react_job)
      end
      
      it 'finds jobs by description' do
        results = Job.search('JavaScript')
        expect(results).to include(react_job)
        expect(results).not_to include(rails_job)
      end
    end
  end
  
  describe 'audit trail' do
    it_behaves_like 'has audit trail'
    
    it 'tracks job publication' do
      expect_audit_log('job.published', job)
      job.publish!
    end
  end
  
  describe 'multi-tenancy' do
    it_behaves_like 'belongs to company'
    
    it 'scopes jobs to current company' do
      company1 = create(:company)
      company2 = create(:company)
      job1 = create(:job, company: company1)
      job2 = create(:job, company: company2)
      
      ActsAsTenant.with_tenant(company1) do
        expect(Job.all).to include(job1)
        expect(Job.all).not_to include(job2)
      end
    end
  end
end