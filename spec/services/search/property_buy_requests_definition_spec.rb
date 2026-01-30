# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Search::PropertyBuyRequestsDefinition", type: :service do
  it "finds buy requests by normalized phone query" do
    agency = create(:agency)
    property = create(:property, agency: agency)
    person = create(:person, normalized_phone: "77001234567")
    contact = create(:contact, agency: agency, person: person)
    request = PropertyBuyRequest.create!(
      property: property,
      agency: agency,
      contact: contact,
      status: :pending
    )

    context = Search::Context.new(agency: agency, user: create(:user))
    results = Search::QueryService.call(
      entity: :property_buy_requests,
      scope: PropertyBuyRequest.where(id: request.id),
      query: "+7 (700) 123-45-67",
      context: context
    )

    expect(results).to contain_exactly(request)
  end
end
