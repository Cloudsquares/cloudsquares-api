# frozen_string_literal: true

# Helper methods for Swagger/rswag request specs
# Provides authentication and factory helpers for API testing

module SwaggerTestHelpers
  # Creates an authenticated user with optional agency association
  #
  # @param role [Symbol] User role (default: :agent_admin)
  # @param with_agency [Boolean] Whether to create and associate an agency (default: true)
  # @return [User] Created user instance
  def create_authenticated_user(role: :agent_admin, with_agency: true)
    phone = "7#{rand(10**9..10**10 - 1)}"
    person = create(:person, normalized_phone: phone)

    user = create(:user,
      person: person,
      role: role,
      email: "user_#{SecureRandom.hex(4)}@example.com",
      password: "SecurePassword1!",
      password_confirmation: "SecurePassword1!",
      country_code: "RU",
      user_status: :active
    )

    if with_agency
      plan = AgencyPlan.find_by(is_default: true) || create(:agency_plan, :default)
      agency = create(:agency, agency_plan: plan, created_by: user)
      create(:user_agency, user: user, agency: agency, is_default: true, status: :active)
    end

    user
  end

  # Creates a user with specific role for authorization testing
  #
  # @param role [Symbol] User role
  # @param agency [Agency, nil] Optional agency to associate with
  # @return [User] Created user instance
  def create_user_with_role(role:, agency: nil)
    phone = "7#{rand(10**9..10**10 - 1)}"
    person = create(:person, normalized_phone: phone)

    user = create(:user,
      person: person,
      role: role,
      email: "#{role}_#{SecureRandom.hex(4)}@example.com",
      password: "SecurePassword1!",
      password_confirmation: "SecurePassword1!",
      country_code: "RU",
      user_status: :active
    )

    if agency
      create(:user_agency, user: user, agency: agency, is_default: true, status: :active)
    end

    user
  end

  # Generates JWT access token for a user
  #
  # @param user [User] User to generate token for
  # @param agency [Agency, nil] Optional agency context
  # @return [String] JWT access token
  def generate_auth_token(user, agency: nil)
    agency_id = agency&.id || user.agencies.find_by(user_agencies: { is_default: true })&.id
    tokens = Auth::JwtService.generate_tokens(user, agency_id: agency_id)
    tokens[:access_token]
  end

  # Returns authorization header hash for requests
  #
  # @param user [User] User to authenticate
  # @param agency [Agency, nil] Optional agency context
  # @return [Hash] Authorization header
  def auth_header_for(user, agency: nil)
    { "Authorization" => "Bearer #{generate_auth_token(user, agency: agency)}" }
  end

  # Creates a complete property with all required associations
  #
  # @param agency [Agency] Agency the property belongs to
  # @param agent [User] Agent managing the property
  # @param status [Symbol] Property status (default: :pending)
  # @return [Property] Created property
  def create_property_with_associations(agency:, agent:, status: :pending)
    category = create(:property_category, agency: agency)
    property = create(:property,
      agency: agency,
      agent: agent,
      category: category,
      status: status,
      title: "Test Property #{SecureRandom.hex(4)}",
      price: rand(100_000..1_000_000),
      listing_type: :sale
    )

    # Create location
    create(:property_location,
      property: property,
      country: "Russia",
      region: "Moscow Oblast",
      city: "Moscow",
      street: "Test Street",
      house_number: rand(1..100).to_s
    )

    property
  end

  # Creates a customer with contact in an agency
  #
  # @param agency [Agency] Agency the customer belongs to
  # @return [Customer] Created customer
  def create_customer_with_contact(agency:)
    phone = "7#{rand(10**9..10**10 - 1)}"
    person = Person.find_by(normalized_phone: phone) || create(:person, normalized_phone: phone)
    contact = create(:contact, agency: agency, person: person, first_name: "Test Customer")
    create(:customer, agency: agency, contact: contact, service_type: :buy)
  end
end

RSpec.configure do |config|
  config.include SwaggerTestHelpers, type: :request
end
