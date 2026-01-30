# frozen_string_literal: true

require "rails_helper"

RSpec.describe Search::QueryParser, type: :service do
  describe ".parse" do
    it "returns nil for blank input" do
      expect(described_class.parse(nil)).to be_nil
      expect(described_class.parse("   ")).to be_nil
    end

    it "masks email and phone for logs" do
      result = described_class.parse("test@example.com +7 (777) 123-45-67")

      expect(result.query).to eq("test@example.com +7 (777) 123-45-67")
      expect(result.masked_query).to include("[email]")
      expect(result.masked_query).to include("[phone]")
    end

    it "raises when query exceeds max length" do
      allow(SearchConfig).to receive(:query_max_length).and_return(5)

      expect { described_class.parse("abcdef") }.to raise_error(Search::QueryTooLongError)
    end
  end
end
