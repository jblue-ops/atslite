# frozen_string_literal: true

# Custom matchers for ATS-specific functionality
RSpec::Matchers.define :have_job_status do |expected_status|
  match do |job|
    job.status == expected_status.to_s
  end

  failure_message do |job|
    "expected job to have status '#{expected_status}', but was '#{job.status}'"
  end

  failure_message_when_negated do |_job|
    "expected job not to have status '#{expected_status}', but it did"
  end
end

RSpec::Matchers.define :have_application_stage do |expected_stage|
  match do |application|
    application.current_stage == expected_stage.to_s
  end

  failure_message do |application|
    "expected application to be in stage '#{expected_stage}', but was '#{application.current_stage}'"
  end
end

RSpec::Matchers.define :be_interview_schedulable do
  match do |application|
    application.present? &&
      application.current_stage.in?(%w[screening interview technical]) &&
      application.candidate.present? &&
      application.job.present?
  end

  failure_message do |application|
    reasons = []
    reasons << "application is nil" if application.nil?
    unless application&.current_stage&.in?(%w[screening interview technical])
      reasons << "stage is #{application.current_stage}"
    end
    reasons << "candidate is missing" if application&.candidate.nil?
    reasons << "job is missing" if application&.job.nil?

    "expected application to be schedulable for interview, but #{reasons.join(", ")}"
  end
end

RSpec::Matchers.define :have_resume_attached do
  match do |candidate|
    candidate.resume.attached?
  end

  failure_message do |_candidate|
    "expected candidate to have resume attached, but resume was not attached"
  end
end

RSpec::Matchers.define :have_valid_email_format do
  match do |user|
    user.email =~ /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i
  end

  failure_message do |user|
    "expected #{user.email} to be a valid email format"
  end
end

RSpec::Matchers.define :be_within_company do |expected_company|
  match do |record|
    record.company_id == expected_company.id
  end

  failure_message do |record|
    "expected record to belong to company #{expected_company.name} (ID: #{expected_company.id}), " \
      "but belonged to company ID: #{record.company_id}"
  end
end

RSpec::Matchers.define :have_upcoming_interviews do
  match do |user|
    user.interviews.upcoming.exists?
  end

  failure_message do |user|
    "expected #{user.class.name} to have upcoming interviews, but none were found"
  end
end

RSpec::Matchers.define :be_authorized_for do |action|
  match do |user|
    @policy_class ||= "#{@subject.class.name}Policy".constantize
    @policy = @policy_class.new(user, @subject)
    @policy.public_send("#{action}?")
  end

  chain :on do |subject|
    @subject = subject
  end

  failure_message do |user|
    "expected #{user.class.name} to be authorized for #{action} on #{@subject.class.name}, but was not"
  end

  failure_message_when_negated do |user|
    "expected #{user.class.name} not to be authorized for #{action} on #{@subject.class.name}, but was"
  end
end

# Custom matcher for checking job application pipeline stages
RSpec::Matchers.define :have_pipeline_stages do |*expected_stages|
  match do |job|
    job.pipeline_stages.map(&:name).sort == expected_stages.map(&:to_s).sort
  end

  failure_message do |job|
    actual_stages = job.pipeline_stages.map(&:name).sort
    expected_stages_str = expected_stages.map(&:to_s).sort
    "expected job to have pipeline stages #{expected_stages_str}, but had #{actual_stages}"
  end
end

# Custom matcher for checking notification delivery
RSpec::Matchers.define :have_sent_notification do |notification_type|
  match do |recipient|
    @notification_type = notification_type
    recipient.notifications.exists?(notification_type: notification_type)
  end

  failure_message do |recipient|
    "expected #{recipient.class.name} to have received #{@notification_type} notification, but didn't"
  end
end
