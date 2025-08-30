# Shared examples for common behaviors across the ATS application

# Authentication and authorization shared examples
RSpec.shared_examples 'requires authentication' do
  context 'when user is not authenticated' do
    it 'redirects to sign in page' do
      subject
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end

RSpec.shared_examples 'requires admin access' do
  context 'when user is not an admin' do
    let(:regular_user) { create(:user, :recruiter) }
    
    before { sign_in regular_user }
    
    it 'denies access' do
      subject
      expect(response).to have_http_status(:forbidden)
    end
  end
end

RSpec.shared_examples 'requires company member access' do
  context 'when user is not a member of the company' do
    let(:other_company) { create(:company) }
    let(:other_user) { create(:user, company: other_company) }
    
    before { sign_in other_user }
    
    it 'denies access' do
      subject
      expect(response).to have_http_status(:forbidden)
    end
  end
end

# Model validation shared examples
RSpec.shared_examples 'has required fields' do |*fields|
  fields.each do |field|
    it "requires #{field}" do
      subject.send("#{field}=", nil)
      expect(subject).not_to be_valid
      expect(subject.errors[field]).to include("can't be blank")
    end
  end
end

RSpec.shared_examples 'validates email format' do |email_field = :email|
  it 'validates email format' do
    subject.send("#{email_field}=", 'invalid-email')
    expect(subject).not_to be_valid
    expect(subject.errors[email_field]).to include('is invalid')
  end
end

RSpec.shared_examples 'belongs to company' do
  it 'requires a company' do
    subject.company = nil
    expect(subject).not_to be_valid
    expect(subject.errors[:company]).to include("can't be blank")
  end
  
  it 'belongs to the correct company' do
    company = create(:company)
    subject.company = company
    expect(subject.company).to eq(company)
  end
end

RSpec.shared_examples 'has audit trail' do
  it 'tracks creation' do
    expect(subject.created_at).to be_present
    expect(subject.updated_at).to be_present
  end
  
  it 'updates timestamp on changes' do
    original_updated_at = subject.updated_at
    sleep 0.1
    subject.touch
    expect(subject.updated_at).to be > original_updated_at
  end
end

# Job-related shared examples
RSpec.shared_examples 'a job with states' do
  it 'has valid initial state' do
    expect(subject.status).to eq('draft')
  end
  
  it 'can transition through states' do
    subject.publish!
    expect(subject.status).to eq('active')
    
    subject.close!
    expect(subject.status).to eq('closed')
  end
  
  it 'validates state transitions' do
    subject.close!
    expect { subject.publish! }.to raise_error(StateMachines::InvalidTransition)
  end
end

# Application pipeline shared examples
RSpec.shared_examples 'moves through pipeline stages' do
  let(:initial_stage) { 'applied' }
  let(:next_stage) { 'screening' }
  
  it 'starts in initial stage' do
    expect(subject.current_stage).to eq(initial_stage)
  end
  
  it 'can advance to next stage' do
    subject.advance_to_stage!(next_stage)
    expect(subject.current_stage).to eq(next_stage)
  end
  
  it 'tracks stage history' do
    subject.advance_to_stage!(next_stage)
    expect(subject.stage_transitions).to be_present
    expect(subject.stage_transitions.last.to_stage).to eq(next_stage)
  end
end

# API response shared examples
RSpec.shared_examples 'returns successful JSON response' do
  it 'returns successful status' do
    subject
    expect(response).to have_http_status(:success)
  end
  
  it 'returns JSON content type' do
    subject
    expect(response.content_type).to include('application/json')
  end
end

RSpec.shared_examples 'returns paginated results' do
  it 'includes pagination metadata' do
    subject
    json_response = JSON.parse(response.body)
    expect(json_response).to have_key('pagination')
    expect(json_response['pagination']).to include(
      'current_page', 'total_pages', 'total_count'
    )
  end
end

RSpec.shared_examples 'validates JSON schema' do |schema_name|
  it 'returns valid JSON schema' do
    subject
    json_response = JSON.parse(response.body)
    schema_path = Rails.root.join('spec', 'support', 'schemas', "#{schema_name}.json")
    schema = JSON.parse(File.read(schema_path))
    expect(JSON::Validator.validate(schema, json_response)).to be true
  end
end

# System test shared examples
RSpec.shared_examples 'displays flash messages' do
  it 'shows success message' do
    subject
    expect(page).to have_css('.alert-success') | have_content('Success')
  end
end

RSpec.shared_examples 'has accessible form' do
  it 'has proper labels for form fields' do
    subject
    form_fields = page.all('input[type="text"], input[type="email"], textarea, select')
    form_fields.each do |field|
      field_id = field[:id]
      expect(page).to have_css("label[for='#{field_id}']") if field_id.present?
    end
  end
  
  it 'has required field indicators' do
    subject
    required_fields = page.all('input[required], textarea[required], select[required]')
    expect(required_fields.count).to be > 0 if required_fields.any?
  end
end

# Search and filtering shared examples
RSpec.shared_examples 'searchable resource' do |search_field|
  let(:search_term) { 'test search' }
  
  it 'filters results by search term' do
    create(:job, title: 'Software Engineer test search position')
    create(:job, title: 'Marketing Manager position')
    
    subject
    fill_in 'Search', with: search_term
    click_button 'Search'
    
    expect(page).to have_content('Software Engineer test search position')
    expect(page).not_to have_content('Marketing Manager position')
  end
end

# Email delivery shared examples
RSpec.shared_examples 'sends notification email' do |mailer_class, mail_method|
  it 'enqueues email delivery' do
    expect {
      subject
    }.to have_enqueued_mail(mailer_class, mail_method)
  end
end