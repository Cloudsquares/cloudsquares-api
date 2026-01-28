# frozen_string_literal: true

# Shared examples for common Swagger response patterns
# Usage: include_examples "unauthorized response"

RSpec.shared_examples "unauthorized response" do
  response "401", "Unauthorized - Invalid or missing token" do
    let(:Authorization) { "Bearer invalid_token" }
    schema "$ref" => "#/components/schemas/Error"

    run_test! do |response|
      expect(response).to have_http_status(:unauthorized)
    end
  end
end

RSpec.shared_examples "forbidden response" do
  response "403", "Forbidden - Insufficient permissions" do
    schema "$ref" => "#/components/schemas/Error"

    run_test! do |response|
      expect(response).to have_http_status(:forbidden)
    end
  end
end

RSpec.shared_examples "not found response" do
  response "404", "Resource not found" do
    schema "$ref" => "#/components/schemas/Error"

    run_test! do |response|
      expect(response).to have_http_status(:not_found)
    end
  end
end

RSpec.shared_examples "validation error response" do
  response "422", "Validation failed" do
    schema "$ref" => "#/components/schemas/ValidationError"

    run_test! do |response|
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end

RSpec.shared_examples "success message response" do
  response "200", "Operation successful" do
    schema "$ref" => "#/components/schemas/SuccessMessage"

    run_test! do |response|
      expect(response).to have_http_status(:ok)
    end
  end
end

RSpec.shared_examples "deleted response" do
  response "200", "Resource deleted successfully" do
    schema "$ref" => "#/components/schemas/SuccessMessage"

    run_test! do |response|
      expect(response).to have_http_status(:ok)
    end
  end
end

# Common parameter definitions for reuse
module SwaggerParameters
  def self.authorization_header
    { name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT token" }
  end

  def self.id_path_param(description = "Resource UUID")
    { name: :id, in: :path, type: :string, format: :uuid, required: true, description: description }
  end

  def self.pagination_params
    [
      { name: :page, in: :query, type: :integer, required: false, description: "Page number (default: 1)" },
      { name: :per_page, in: :query, type: :integer, required: false, description: "Items per page (default: 20, max: 100)" }
    ]
  end

  def self.sorting_params(allowed_fields = %w[created_at])
    [
      { name: :sort_by, in: :query, type: :string, required: false, enum: allowed_fields, description: "Sort field" },
      { name: :sort_dir, in: :query, type: :string, required: false, enum: %w[asc desc], description: "Sort direction" }
    ]
  end

  def self.agency_id_query
    { name: :agency_id, in: :query, type: :string, format: :uuid, required: true, description: "Agency UUID" }
  end
end
