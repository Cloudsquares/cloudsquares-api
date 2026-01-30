# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Search::UsersDefinition", type: :service do
  it "finds users by profile name" do
    agency = create(:agency)
    user = create(:user, :agent, password: "SecurePassword1!")
    create(:user_agency, user: user, agency: agency, is_default: true, status: :active)
    user.profile.update!(first_name: "Boss", last_name: "Ivanov")

    context = Search::Context.new(agency: agency, user: user)
    results = Search::QueryService.call(
      entity: :users,
      scope: User.where(id: user.id),
      query: "Boss",
      context: context
    )

    expect(results).to contain_exactly(user)
  end

  it "finds users by normalized phone query" do
    agency = create(:agency)
    person = create(:person, normalized_phone: "77001234567")
    user = create(:user, :agent, person: person, password: "SecurePassword1!")
    create(:user_agency, user: user, agency: agency, is_default: true, status: :active)

    context = Search::Context.new(agency: agency, user: user)
    results = Search::QueryService.call(
      entity: :users,
      scope: User.where(id: user.id),
      query: "+7 (700) 123-45-67",
      context: context
    )

    expect(results).to contain_exactly(user)
  end
end
