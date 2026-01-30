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
end
