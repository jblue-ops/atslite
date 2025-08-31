# frozen_string_literal: true

# Request helpers for API testing
module RequestHelpers
  # JSON request helpers
  def json_headers(user = nil)
    headers = { "Content-Type" => "application/json" }
    headers.merge!(auth_headers(user)) if user
    headers
  end

  def get_json(path, params: {}, headers: {}, user: nil)
    get path, params: params, headers: json_headers(user).merge(headers), as: :json
  end

  def post_json(path, params: {}, headers: {}, user: nil)
    post path, params: params.to_json, headers: json_headers(user).merge(headers)
  end

  def put_json(path, params: {}, headers: {}, user: nil)
    put path, params: params.to_json, headers: json_headers(user).merge(headers)
  end

  def patch_json(path, params: {}, headers: {}, user: nil)
    patch path, params: params.to_json, headers: json_headers(user).merge(headers)
  end

  def delete_json(path, params: {}, headers: {}, user: nil)
    delete path, params: params.to_json, headers: json_headers(user).merge(headers)
  end

  # Response parsing helpers
  def json_response
    JSON.parse(response.body)
  end

  def json_response_symbolized
    JSON.parse(response.body, symbolize_names: true)
  end

  # API response expectations
  def expect_json_response(status = :ok)
    expect(response).to have_http_status(status)
    expect(response.content_type).to include("application/json")
  end

  def expect_successful_json_response
    expect_json_response(:ok)
    expect(json_response).to be_present
  end

  def expect_created_json_response
    expect_json_response(:created)
    expect(json_response).to have_key("id")
  end

  def expect_error_json_response(status = :unprocessable_entity)
    expect_json_response(status)
    expect(json_response).to have_key("errors")
  end

  def expect_unauthorized_response
    expect(response).to have_http_status(:unauthorized)
    expect(json_response).to have_key("error")
  end

  def expect_forbidden_response
    expect(response).to have_http_status(:forbidden)
    expect(json_response).to have_key("error")
  end

  def expect_not_found_response
    expect(response).to have_http_status(:not_found)
    expect(json_response).to have_key("error")
  end

  # Pagination helpers
  def expect_paginated_response
    expect(json_response).to have_key("data")
    expect(json_response).to have_key("pagination")
    expect(json_response["pagination"]).to include(
      "current_page", "total_pages", "total_count", "per_page"
    )
  end

  def expect_empty_paginated_response
    expect_paginated_response
    expect(json_response["data"]).to be_empty
    expect(json_response["pagination"]["total_count"]).to eq(0)
  end

  # Resource-specific helpers for ATS
  def expect_job_response(job = nil)
    expect_successful_json_response
    expect(json_response).to have_key("title")
    expect(json_response).to have_key("description")
    expect(json_response).to have_key("status")
    expect(json_response).to have_key("company_id")

    return unless job

    expect(json_response["id"]).to eq(job.id)
    expect(json_response["title"]).to eq(job.title)
  end

  def expect_candidate_response(candidate = nil)
    expect_successful_json_response
    expect(json_response).to have_key("first_name")
    expect(json_response).to have_key("last_name")
    expect(json_response).to have_key("email")

    return unless candidate

    expect(json_response["id"]).to eq(candidate.id)
    expect(json_response["email"]).to eq(candidate.email)
  end

  def expect_application_response(application = nil)
    expect_successful_json_response
    expect(json_response).to have_key("job_id")
    expect(json_response).to have_key("candidate_id")
    expect(json_response).to have_key("current_stage")
    expect(json_response).to have_key("applied_at")

    return unless application

    expect(json_response["id"]).to eq(application.id)
    expect(json_response["current_stage"]).to eq(application.current_stage)
  end

  def expect_interview_response(interview = nil)
    expect_successful_json_response
    expect(json_response).to have_key("application_id")
    expect(json_response).to have_key("interviewer_id")
    expect(json_response).to have_key("scheduled_at")
    expect(json_response).to have_key("status")

    return unless interview

    expect(json_response["id"]).to eq(interview.id)
    expect(json_response["status"]).to eq(interview.status)
  end

  # File upload helpers
  def upload_file(_field_name, filename, content_type = "text/plain")
    file_path = Rails.root.join("spec", "fixtures", "files", filename)
    Rack::Test::UploadedFile.new(file_path, content_type)
  end

  def upload_pdf(filename = "sample_resume.pdf")
    upload_file("resume", filename, "application/pdf")
  end

  def upload_image(filename = "sample_image.jpg")
    upload_file("image", filename, "image/jpeg")
  end

  # Rate limiting helpers
  def expect_rate_limited_response
    expect(response).to have_http_status(:too_many_requests)
    expect(json_response).to have_key("error")
    expect(json_response["error"]).to include("rate limit")
  end

  # Validation error helpers
  def expect_validation_errors(*fields)
    expect_error_json_response
    fields.each do |field|
      expect(json_response["errors"]).to have_key(field.to_s)
    end
  end

  # Search and filter helpers
  def expect_filtered_results(expected_count = nil)
    expect_successful_json_response
    return unless expected_count

    expect(json_response["data"].length).to eq(expected_count)
  end
end

# Multi-tenant request helpers
module MultiTenantRequestHelpers
  def with_tenant(company, &)
    ActsAsTenant.with_tenant(company, &)
  end

  def get_json_with_tenant(company, path, **args)
    with_tenant(company) { get_json(path, **args) }
  end

  def post_json_with_tenant(company, path, **args)
    with_tenant(company) { post_json(path, **args) }
  end

  def put_json_with_tenant(company, path, **args)
    with_tenant(company) { put_json(path, **args) }
  end

  def delete_json_with_tenant(company, path, **args)
    with_tenant(company) { delete_json(path, **args) }
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
  config.include MultiTenantRequestHelpers, type: :request
end
