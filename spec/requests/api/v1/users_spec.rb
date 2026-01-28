# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Users API", type: :request do
  # ============================================
  # GET /api/v1/me
  # ============================================
  path "/api/v1/me" do
    get "Get current user profile" do
      tags "Users"
      operationId "getCurrentUser"
      description "Returns the authenticated user's profile with agency context."
      produces "application/json"
      security [ { Bearer: [] } ]

      parameter name: :Authorization, in: :header, type: :string, required: true,
        description: "Bearer JWT access token"

      response "200", "Current user profile" do
        schema "$ref" => "#/components/schemas/User"

        let(:user) { create_authenticated_user(role: :agent_admin) }
        let(:Authorization) { "Bearer #{generate_auth_token(user)}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["id"]).to eq(user.id)
          expect(data["role"]).to eq("agent_admin")
        end
      end

      response "401", "Unauthorized" do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { "Bearer invalid_token" }

        run_test!
      end
    end
  end

  # ============================================
  # PATCH /api/v1/me
  # ============================================
  path "/api/v1/me" do
    patch "Update current user profile" do
      tags "Users"
      operationId "updateCurrentUser"
      description <<~DESC
        Update the authenticated user's profile.

        **Updatable fields:**
        - Profile info: first_name, last_name, middle_name, timezone, locale, avatar_url
        - Email (must be unique)
        - Password (requires current_password for verification)
        - Preferences: notification_prefs, ui_prefs

        Name changes are stored in the user's profile (not agency Contact).
      DESC
      consumes "application/json"
      produces "application/json"
      security [ { Bearer: [] } ]

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :user, in: :body, schema: {
        "$ref" => "#/components/schemas/UserUpdateRequest"
      }

      response "200", "Profile updated" do
        schema "$ref" => "#/components/schemas/User"

        let(:current_user) { create_authenticated_user(role: :agent_admin) }
        let(:Authorization) { "Bearer #{generate_auth_token(current_user)}" }
        let(:user) do
          {
            user: {
              first_name: "Updated",
              last_name: "Name",
              timezone: "Europe/London",
              locale: "en"
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["timezone"]).to eq("Europe/London")
          expect(data["locale"]).to eq("en")
        end
      end

      response "401", "Unauthorized" do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { "Bearer invalid_token" }
        let(:user) { { user: { first_name: "Test" } } }

        run_test!
      end
    end
  end

  # ============================================
  # GET /api/v1/users
  # ============================================
  path "/api/v1/users" do
    get "List users" do
      tags "Users"
      operationId "listUsers"
      description <<~DESC
        List users visible to the authenticated user based on their role and agency.

        - Admins see all users
        - Agency admins see users in their agency
        - Regular users have limited access
      DESC
      produces "application/json"
      security [ { Bearer: [] } ]

      parameter name: :Authorization, in: :header, type: :string, required: true

      response "200", "List of users" do
        schema type: :array, items: { "$ref" => "#/components/schemas/User" }

        let(:user) { create_authenticated_user(role: :agent_admin) }
        let(:Authorization) { "Bearer #{generate_auth_token(user)}" }

        before do
          agency = user.agencies.first
          # Create additional users in the same agency
          2.times do
            other_user = create(:user, :agent, password: "SecurePassword1!")
            create(:user_agency, user: other_user, agency: agency, status: :active)
          end
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
        end
      end

      response "401", "Unauthorized" do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { "Bearer invalid_token" }

        run_test!
      end
    end
  end

  # ============================================
  # GET /api/v1/users/:id
  # ============================================
  path "/api/v1/users/{id}" do
    get "Get user by ID" do
      tags "Users"
      operationId "getUser"
      description "Retrieve a specific user's details. Authorization rules apply based on role and agency."
      produces "application/json"
      security [ { Bearer: [] } ]

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, format: :uuid, required: true,
        description: "User UUID"

      response "200", "User details" do
        schema "$ref" => "#/components/schemas/User"

        let(:admin_user) { create_authenticated_user(role: :agent_admin) }
        let(:Authorization) { "Bearer #{generate_auth_token(admin_user)}" }
        let(:agency) { admin_user.agencies.first }
        let(:target_user) do
          u = create(:user, :agent, password: "SecurePassword1!")
          create(:user_agency, user: u, agency: agency, status: :active)
          u
        end
        let(:id) { target_user.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["id"]).to eq(target_user.id)
        end
      end

      response "401", "Unauthorized" do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { "Bearer invalid_token" }
        let(:id) { SecureRandom.uuid }

        run_test!
      end

      response "404", "User not found" do
        schema "$ref" => "#/components/schemas/Error"

        let(:user) { create_authenticated_user(role: :admin) }
        let(:Authorization) { "Bearer #{generate_auth_token(user)}" }
        let(:id) { SecureRandom.uuid }

        run_test!
      end
    end
  end

  # ============================================
  # POST /api/v1/users
  # ============================================
  path "/api/v1/users" do
    post "Create user (agency employee)" do
      tags "Users"
      operationId "createUser"
      description <<~DESC
        Create a new user (employee) in the current agency.

        **Requirements:**
        - Authenticated user must have an agency
        - Cannot create admin or admin_manager roles
        - Phone number must be unique

        **Creates:**
        - Person (global identity by phone)
        - User (with specified role)
        - UserAgency (links to current agency)
        - Contact (in the agency with provided name/email)
      DESC
      consumes "application/json"
      produces "application/json"
      security [ { Bearer: [] } ]

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :user, in: :body, schema: {
        "$ref" => "#/components/schemas/UserCreateRequest"
      }

      response "201", "User created" do
        schema "$ref" => "#/components/schemas/User"

        let(:admin_user) { create_authenticated_user(role: :agent_admin) }
        let(:Authorization) { "Bearer #{generate_auth_token(admin_user)}" }
        let(:user) do
          {
            user: {
              phone: "77008887766",
              email: "newemployee@agency.com",
              password: "SecurePassword1!",
              password_confirmation: "SecurePassword1!",
              role: "agent",
              country_code: "RU",
              first_name: "New",
              last_name: "Employee"
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["role"]).to eq("agent")
        end
      end

      response "403", "Cannot create admin role" do
        schema "$ref" => "#/components/schemas/Error"

        let(:admin_user) { create_authenticated_user(role: :agent_admin) }
        let(:Authorization) { "Bearer #{generate_auth_token(admin_user)}" }
        let(:user) do
          {
            user: {
              phone: "77008887755",
              email: "admin@test.com",
              password: "SecurePassword1!",
              password_confirmation: "SecurePassword1!",
              role: "admin",
              country_code: "RU"
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.dig("error", "key")).to eq("users.admin_not_allowed")
        end
      end

      response "422", "Phone already registered" do
        schema "$ref" => "#/components/schemas/Error"

        let(:existing_person) { create(:person, normalized_phone: "77001234567") }
        let!(:existing_user) { create(:user, person: existing_person) }
        let(:admin_user) { create_authenticated_user(role: :agent_admin) }
        let(:Authorization) { "Bearer #{generate_auth_token(admin_user)}" }
        let(:user) do
          {
            user: {
              phone: "77001234567",
              email: "duplicate@test.com",
              password: "SecurePassword1!",
              password_confirmation: "SecurePassword1!",
              role: "agent",
              country_code: "RU"
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.dig("error", "key")).to eq("users.phone_already_registered")
        end
      end

      response "422", "Invalid phone format" do
        schema "$ref" => "#/components/schemas/Error"

        let(:admin_user) { create_authenticated_user(role: :agent_admin) }
        let(:Authorization) { "Bearer #{generate_auth_token(admin_user)}" }
        let(:user) do
          {
            user: {
              phone: "123",
              email: "test@test.com",
              password: "SecurePassword1!",
              password_confirmation: "SecurePassword1!",
              role: "agent",
              country_code: "RU"
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.dig("error", "key")).to eq("users.phone_invalid")
        end
      end

      response "401", "Unauthorized" do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { "Bearer invalid_token" }
        let(:user) { { user: { phone: "77001234567" } } }

        run_test!
      end
    end
  end

  # ============================================
  # PATCH /api/v1/users/:id
  # ============================================
  path "/api/v1/users/{id}" do
    patch "Update user" do
      tags "Users"
      operationId "updateUser"
      description <<~DESC
        Update a user's information.

        **Updatable fields:**
        - Phone (updates Person, must be unique)
        - Email, password
        - Name fields (update Contact in current agency)
        - Profile settings: timezone, locale, avatar_url, prefs
      DESC
      consumes "application/json"
      produces "application/json"
      security [ { Bearer: [] } ]

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, format: :uuid, required: true
      parameter name: :user, in: :body, schema: {
        "$ref" => "#/components/schemas/UserUpdateRequest"
      }

      response "200", "User updated" do
        schema "$ref" => "#/components/schemas/User"

        let(:admin_user) { create_authenticated_user(role: :agent_admin) }
        let(:Authorization) { "Bearer #{generate_auth_token(admin_user)}" }
        let(:agency) { admin_user.agencies.first }
        let(:target_user) do
          u = create(:user, :agent, password: "SecurePassword1!")
          create(:user_agency, user: u, agency: agency, status: :active)
          create(:contact, agency: agency, person: u.person, first_name: "Original")
          u
        end
        let(:id) { target_user.id }
        let(:user) do
          {
            user: {
              first_name: "Updated",
              last_name: "Employee"
            }
          }
        end

        run_test!
      end

      response "401", "Unauthorized" do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { "Bearer invalid_token" }
        let(:id) { SecureRandom.uuid }
        let(:user) { { user: { first_name: "Test" } } }

        run_test!
      end

      response "404", "User not found" do
        schema "$ref" => "#/components/schemas/Error"

        let(:admin_user) { create_authenticated_user(role: :admin) }
        let(:Authorization) { "Bearer #{generate_auth_token(admin_user)}" }
        let(:id) { SecureRandom.uuid }
        let(:user) { { user: { first_name: "Test" } } }

        run_test!
      end
    end
  end

  # ============================================
  # DELETE /api/v1/users/:id
  # ============================================
  path "/api/v1/users/{id}" do
    delete "Delete user (soft delete)" do
      tags "Users"
      operationId "deleteUser"
      description <<~DESC
        Soft delete a user by setting `is_active` to false.

        The user record is preserved but marked as deleted.
        Cannot delete an already deleted user.
      DESC
      produces "application/json"
      security [ { Bearer: [] } ]

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, format: :uuid, required: true

      response "200", "User deleted" do
        schema "$ref" => "#/components/schemas/SuccessMessage"

        let(:admin_user) { create_authenticated_user(role: :agent_admin) }
        let(:Authorization) { "Bearer #{generate_auth_token(admin_user)}" }
        let(:agency) { admin_user.agencies.first }
        let(:target_user) do
          u = create(:user, :agent, password: "SecurePassword1!")
          create(:user_agency, user: u, agency: agency, status: :active)
          u
        end
        let(:id) { target_user.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.dig("success", "key")).to eq("users.deleted")
          expect(target_user.reload.is_active).to be false
        end
      end

      response "400", "User already deleted" do
        schema "$ref" => "#/components/schemas/Error"

        let(:admin_user) { create_authenticated_user(role: :agent_admin) }
        let(:Authorization) { "Bearer #{generate_auth_token(admin_user)}" }
        let(:agency) { admin_user.agencies.first }
        let(:deleted_user) do
          u = create(:user, :agent, :inactive, password: "SecurePassword1!")
          create(:user_agency, user: u, agency: agency, status: :active)
          u
        end
        let(:id) { deleted_user.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.dig("error", "key")).to eq("user.delete_deleted_user")
        end
      end

      response "401", "Unauthorized" do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { "Bearer invalid_token" }
        let(:id) { SecureRandom.uuid }

        run_test!
      end

      response "404", "User not found" do
        schema "$ref" => "#/components/schemas/Error"

        let(:admin_user) { create_authenticated_user(role: :admin) }
        let(:Authorization) { "Bearer #{generate_auth_token(admin_user)}" }
        let(:id) { SecureRandom.uuid }

        run_test!
      end
    end
  end
end
