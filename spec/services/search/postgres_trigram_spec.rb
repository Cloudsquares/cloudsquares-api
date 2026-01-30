# frozen_string_literal: true

require "rails_helper"

RSpec.describe Search::Providers::PostgresTrigram, type: :service do
  describe "#build_text_predicate" do
    it "builds a safe ILIKE predicate" do
      provider = described_class.new
      expression = User.arel_table[:email]

      predicate = provider.build_text_predicate(expression, "Test%")

      expect(predicate).to be_a(Arel::Nodes::Matches)
      expect(predicate.left).to eq(expression)
      expect(predicate.right.value).to include("Test")
    end
  end
end
