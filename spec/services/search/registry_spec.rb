# frozen_string_literal: true

require "rails_helper"

RSpec.describe Search::Registry, type: :service do
  describe ".definition_for" do
    it "returns definition for properties" do
      definition = described_class.definition_for(:properties)

      expect(definition).to be_a(Search::Definitions::PropertiesDefinition)
    end

    it "raises for unknown entity" do
      expect { described_class.definition_for(:unknown_entity) }
        .to raise_error(ArgumentError, /Search definition not found/)
    end
  end
end
