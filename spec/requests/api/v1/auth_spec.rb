# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Authentication API", type: :request do
  # ============================================
  # POST /api/v1/auth/login
  # ============================================
  path "/api/v1/auth/login" do
    post "User login" do
      tags "Authentication"
      operationId "login"
      description <<~DESC
        Authenticate user with phone and password. Returns JWT access and refresh tokens.

        Optional `agency_id` or `property_id` can be passed to set the agency context in the token.
        If `property_id` is provided, the agency is derived from the property.
      DESC
      consumes "application/json"
      produces "application/json"
      security []

      parameter name: :credentials, in: :body, schema: {
        "$ref" => "#/components/schemas/LoginRequest"
      }

      response "200", "Login successful" do
        schema "$ref" => "#/components/schemas/AuthTokens"

        let(:person) { create(:person) }
        let!(:user) { create(:user, person: person, password: "SecurePassword1!") }
        let(:credentials) { { phone: person.normalized_phone, password: "SecurePassword1!" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["access_token"]).to be_present
          expect(data["refresh_token"]).to be_present
          expect(data["expires_in"]).to be_present
        end
      end

      response "200", "Login with agency context" do
        schema "$ref" => "#/components/schemas/AuthTokens"

        let(:person) { create(:person) }
        let!(:user) { create(:user, :agent_admin, person: person, password: "SecurePassword1!") }
        let(:agency) { create(:agency) }
        let!(:user_agency) { create(:user_agency, user: user, agency: agency, is_default: true) }
        let(:credentials) { { phone: person.normalized_phone, password: "SecurePassword1!", agency_id: agency.id } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["access_token"]).to be_present
        end
      end

      response "401", "Invalid credentials" do
        schema "$ref" => "#/components/schemas/Error"

        let(:person) { create(:person) }
        let!(:user) { create(:user, person: person) }
        let(:credentials) { { phone: person.normalized_phone, password: "wrong_password" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.dig("error", "key")).to eq("auth.invalid_credentials")
        end
      end

      response "401", "Invalid phone format" do
        schema "$ref" => "#/components/schemas/Error"

        let(:credentials) { { phone: "123", password: "SecurePassword1!" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.dig("error", "key")).to eq("auth.invalid_phone")
        end
      end

      response "401", "User not found" do
        schema "$ref" => "#/components/schemas/Error"

        let(:credentials) { { phone: "77009999999", password: "SecurePassword1!" } }

        run_test!
      end
    end
  end

  # ============================================
  # POST /api/v1/auth/refresh
  # ============================================
  path "/api/v1/auth/refresh" do
    post "Refresh tokens" do
      tags "Authentication"
      operationId "refreshTokens"
      description <<~DESC
        Exchange a valid refresh token for a new access/refresh token pair.

        Optionally pass `agency_id` to change the agency context in the new token.
      DESC
      consumes "application/json"
      produces "application/json"
      security []

      parameter name: :body, in: :body, schema: {
        "$ref" => "#/components/schemas/RefreshRequest"
      }

      response "200", "Tokens refreshed successfully" do
        schema type: :object,
          properties: {
            access_token: { type: :string },
            refresh_token: { type: :string }
          },
          required: %w[access_token refresh_token]

        let(:user) { create_authenticated_user }
        let(:tokens) { Auth::JwtService.generate_tokens(user) }
        let(:body) { { refresh_token: tokens[:refresh_token] } }

        before { Auth::TokenStorageRedis.save(user_id: user.id, iat: tokens[:iat]) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["access_token"]).to be_present
          expect(data["refresh_token"]).to be_present
        end
      end

      response "401", "Invalid refresh token" do
        schema "$ref" => "#/components/schemas/Error"

        let(:body) { { refresh_token: "invalid_token_here" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.dig("error", "code")).to eq(401)
        end
      end

      response "401", "Expired or revoked refresh token" do
        schema "$ref" => "#/components/schemas/Error"

        let(:user) { create_authenticated_user }
        let(:tokens) { Auth::JwtService.generate_tokens(user) }
        let(:body) { { refresh_token: tokens[:refresh_token] } }

        # Don't save to Redis - simulates revoked/expired token

        run_test!
      end
    end
  end

  # ============================================
  # POST /api/v1/auth/logout
  # ============================================
  path "/api/v1/auth/logout" do
    post "Logout" do
      tags "Authentication"
      operationId "logout"
      description "Invalidate the user's refresh token. Requires authentication."
      produces "application/json"
      security [ { Bearer: [] } ]

      parameter name: :Authorization, in: :header, type: :string, required: true,
        description: "Bearer JWT access token"

      response "200", "Logout successful" do
        schema "$ref" => "#/components/schemas/SuccessMessage"

        let(:user) { create_authenticated_user }
        let(:Authorization) { "Bearer #{generate_auth_token(user)}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.dig("success", "key")).to eq("auth.logout")
        end
      end

      response "401", "Unauthorized - Invalid or missing token" do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { "Bearer invalid_token" }

        run_test!
      end
    end
  end

  # ============================================
  # POST /api/v1/auth/register-user
  # ============================================
  path "/api/v1/auth/register-user" do
    post "Register B2C user" do
      tags "Authentication"
      operationId "registerUser"
      description <<~DESC
        Register a B2C buyer in an agency context.

        **Requirements:**
        - Must provide either `agency_id` or `property_id` to determine the agency context
        - Phone number must be unique (not already registered)

        **Creates:**
        - Person (global identity by phone)
        - User (role: user)
        - Contact (in the agency)
        - Customer (service_type: buy)

        Returns user data and JWT tokens with agency context.
      DESC
      consumes "application/json"
      produces "application/json"
      security []

      parameter name: :user, in: :body, schema: {
        "$ref" => "#/components/schemas/RegisterUserRequest"
      }

      response "201", "User registered successfully" do
        schema "$ref" => "#/components/schemas/AuthResponse"

        let(:agency) { create(:agency) }
        let(:user) do
          {
            user: {
              phone: "77009876543",
              email: "newbuyer@example.com",
              password: "SecurePassword1!",
              password_confirmation: "SecurePassword1!",
              country_code: "RU",
              first_name: "Test",
              last_name: "Buyer",
              agency_id: agency.id
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["user"]).to be_present
          expect(data["user"]["role"]).to eq("user")
          expect(data["access_token"]).to be_present
          expect(data["refresh_token"]).to be_present
        end
      end

      response "201", "User registered via property context" do
        schema "$ref" => "#/components/schemas/AuthResponse"

        let(:agency) { create(:agency) }
        let(:property) { create(:property, agency: agency) }
        let(:user) do
          {
            user: {
              phone: "77009876544",
              email: "buyer2@example.com",
              password: "SecurePassword1!",
              password_confirmation: "SecurePassword1!",
              country_code: "KZ",
              first_name: "Property",
              property_id: property.id
            }
          }
        end

        run_test!
      end

      response "422", "Missing agency context" do
        schema "$ref" => "#/components/schemas/Error"

        let(:user) do
          {
            user: {
              phone: "77009876545",
              email: "noagency@example.com",
              password: "SecurePassword1!",
              password_confirmation: "SecurePassword1!",
              country_code: "RU"
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.dig("error", "key")).to eq("auth.agency_required")
        end
      end

      response "422", "Phone already registered" do
        schema "$ref" => "#/components/schemas/Error"

        let(:existing_person) { create(:person, normalized_phone: "77001112233") }
        let!(:existing_user) { create(:user, person: existing_person) }
        let(:agency) { create(:agency) }
        let(:user) do
          {
            user: {
              phone: "77001112233",
              email: "duplicate@example.com",
              password: "SecurePassword1!",
              password_confirmation: "SecurePassword1!",
              country_code: "RU",
              agency_id: agency.id
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.dig("error", "key")).to eq("auth.phone_taken")
        end
      end

      response "422", "Invalid phone format" do
        schema "$ref" => "#/components/schemas/Error"

        let(:agency) { create(:agency) }
        let(:user) do
          {
            user: {
              phone: "123",
              email: "invalid@example.com",
              password: "SecurePassword1!",
              password_confirmation: "SecurePassword1!",
              country_code: "RU",
              agency_id: agency.id
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.dig("error", "key")).to eq("auth.invalid_phone")
        end
      end

      response "422", "Validation errors (weak password)" do
        schema "$ref" => "#/components/schemas/ValidationError"

        let(:agency) { create(:agency) }
        let(:user) do
          {
            user: {
              phone: "77009876546",
              email: "weak@example.com",
              password: "weak",
              password_confirmation: "weak",
              country_code: "RU",
              agency_id: agency.id
            }
          }
        end

        run_test!
      end
    end
  end

  # ============================================
  # POST /api/v1/auth/register-agent-with-agency
  # ============================================
  path "/api/v1/auth/register-agent-with-agency" do
    post "Register B2B agent with agency" do
      tags "Authentication"
      operationId "registerAgentWithAgency"
      description <<~DESC
        Atomic B2B registration that creates a user and agency together.

        **Creates:**
        - Person (global identity by phone)
        - User (role: agent_admin)
        - Agency (with default or specified plan)
        - UserAgency (links user to agency as default)
        - Contact (in the new agency)
        - AgencySetting (default settings)

        Returns user data and JWT tokens with the new agency context.
      DESC
      consumes "application/json"
      produces "application/json"
      security []

      parameter name: :body, in: :body, schema: {
        "$ref" => "#/components/schemas/RegisterAgentWithAgencyRequest"
      }

      response "201", "Agent and agency created successfully" do
        schema "$ref" => "#/components/schemas/AuthResponse"

        let!(:default_plan) { create(:agency_plan, :default) }
        let(:body) do
          {
            user: {
              phone: "77001112244",
              email: "agent@newagency.com",
              password: "SecurePassword1!",
              password_confirmation: "SecurePassword1!",
              country_code: "RU",
              first_name: "Agent",
              last_name: "Smith"
            },
            agency: {
              title: "Smith Realty"
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["user"]).to be_present
          expect(data["user"]["role"]).to eq("agent_admin")
          expect(data["access_token"]).to be_present
          expect(data["refresh_token"]).to be_present
        end
      end

      response "201", "Agent with custom agency slug and plan" do
        schema "$ref" => "#/components/schemas/AuthResponse"

        let!(:custom_plan) { create(:agency_plan, :professional) }
        let(:body) do
          {
            user: {
              phone: "77001112255",
              email: "premium@agency.com",
              password: "SecurePassword1!",
              password_confirmation: "SecurePassword1!",
              country_code: "KZ",
              first_name: "Premium"
            },
            agency: {
              title: "Premium Properties",
              slug: "premium-properties",
              agency_plan_id: custom_plan.id
            }
          }
        end

        run_test!
      end

      response "422", "Phone already registered" do
        schema "$ref" => "#/components/schemas/Error"

        let(:existing_person) { create(:person, normalized_phone: "77005556666") }
        let!(:existing_user) { create(:user, person: existing_person) }
        let!(:default_plan) { create(:agency_plan, :default) }
        let(:body) do
          {
            user: {
              phone: "77005556666",
              email: "duplicate@agency.com",
              password: "SecurePassword1!",
              password_confirmation: "SecurePassword1!",
              country_code: "RU"
            },
            agency: {
              title: "Duplicate Agency"
            }
          }
        end

        run_test!
      end

      response "422", "Validation errors" do
        schema "$ref" => "#/components/schemas/ValidationError"

        let!(:default_plan) { create(:agency_plan, :default) }
        let(:body) do
          {
            user: {
              phone: "77001112277",
              email: "bad@agency.com",
              password: "short",
              password_confirmation: "short",
              country_code: "RU"
            },
            agency: {
              title: ""
            }
          }
        end

        run_test!
      end

      response "422", "Slug already taken" do
        schema "$ref" => "#/components/schemas/Error"

        let!(:existing_agency) { create(:agency, slug: "taken-slug") }
        let!(:default_plan) { create(:agency_plan, :default) }
        let(:body) do
          {
            user: {
              phone: "77001112288",
              email: "newagent@agency.com",
              password: "SecurePassword1!",
              password_confirmation: "SecurePassword1!",
              country_code: "RU"
            },
            agency: {
              title: "New Agency",
              slug: "taken-slug"
            }
          }
        end

        run_test!
      end
    end
  end

  # ============================================
  # POST /api/v1/auth/register-agent (DEPRECATED)
  # ============================================
  path "/api/v1/auth/register-agent" do
    post "Register agent admin (DEPRECATED)" do
      tags "Authentication"
      operationId "registerAgentAdmin"
      deprecated true
      description <<~DESC
        **DEPRECATED**: Use `/api/v1/auth/register-agent-with-agency` instead.

        Creates an agent_admin user without an agency. This endpoint is kept for
        backwards compatibility but should not be used for new integrations.
      DESC
      consumes "application/json"
      produces "application/json"
      security []

      parameter name: :user, in: :body, schema: {
        "$ref" => "#/components/schemas/RegisterUserRequest"
      }

      response "201", "Agent registered (deprecated)" do
        schema "$ref" => "#/components/schemas/AuthResponse"

        let(:agency) { create(:agency) }
        let(:user) do
          {
            user: {
              phone: "77009998877",
              email: "deprecated@agent.com",
              password: "SecurePassword1!",
              password_confirmation: "SecurePassword1!",
              country_code: "RU",
              first_name: "Deprecated",
              agency_id: agency.id
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["user"]["role"]).to eq("agent_admin")
        end
      end

      response "422", "Validation error" do
        schema "$ref" => "#/components/schemas/Error"

        let(:user) do
          {
            user: {
              phone: "123",
              password: "weak"
            }
          }
        end

        run_test!
      end
    end
  end
end
