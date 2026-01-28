# TODO: проверить содержимое тестов и их работоспособность
# использовать FactoryBot
require "rails_helper"

RSpec.describe Shared::LimitChecker, type: :service do
  let(:agency_plan) { create(:agency_plan, max_employees: 3, max_properties: 2) }
  let(:agency) { create(:agency, agency_plan: agency_plan) }

  def create_agent_for(agency)
    user = create(:user, :agent)
    create(:user_agency, :default, user: user, agency: agency, status: :active)
    user
  end

  describe ".exceeded?" do
    context "when agency has not exceeded the employee limit" do
      before do
        2.times { create_agent_for(agency) }
      end

      it "returns false" do
        expect(Shared::LimitChecker.exceeded?(:employees, agency)).to eq(false)
      end
    end

    context "when agency has reached the employee limit" do
      before do
        3.times { create_agent_for(agency) }
      end

      it "returns true" do
        expect(Shared::LimitChecker.exceeded?(:employees, agency)).to eq(true)
      end
    end

    context "when agency plan has no limits (null)" do
      it "returns false" do
        skip "max_employees является обязательным полем в БД"
      end
    end

    context "when unknown limit key is passed" do
      it "raises an error" do
        expect {
          Shared::LimitChecker.exceeded?(:unknown_limit, agency)
        }.to raise_error(ArgumentError, /Unknown limit key/)
      end
    end

    context "when agency has no plan" do
      before { agency.update_column(:agency_plan_id, nil) }

      it "returns false" do
        expect(Shared::LimitChecker.exceeded?(:employees, agency)).to eq(false)
      end
    end
  end
end
