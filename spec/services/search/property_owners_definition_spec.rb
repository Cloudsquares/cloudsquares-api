# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Search::PropertyOwnersDefinition", type: :service do
  it "finds owners by normalized phone query" do
    agency = create(:agency)
    property = create(:property, agency: agency)
    person = create(:person, normalized_phone: "77001234567")
    contact = create(:contact, agency: agency, person: person)
    owner = PropertyOwner.create!(
      property: property,
      contact: contact,
      role: :primary
    )

    context = Search::Context.new(agency: agency, user: create(:user))
    results = Search::QueryService.call(
      entity: :property_owners,
      scope: PropertyOwner.where(id: owner.id),
      query: "+7 (700) 123-45-67",
      context: context
    )

    expect(results).to contain_exactly(owner)
  end
end
