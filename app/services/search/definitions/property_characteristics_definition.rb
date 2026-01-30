# frozen_string_literal: true

module Search
  module Definitions
    # PropertyCharacteristicsDefinition — правила поиска по характеристикам недвижимости.
    class PropertyCharacteristicsDefinition < BaseDefinition
      def initialize
        super(entity: :property_characteristics, distinct: false)
      end

      # Возвращает предикаты поиска по title и id (UUID как текст).
      #
      # @param query [String]
      # @param context [Search::Context]
      # @param provider [Search::Provider]
      # @return [Array<Arel::Nodes::Node>]
      def predicates(query:, context:, provider:)
        characteristics = PropertyCharacteristic.arel_table
        id_expr = Arel.sql("property_characteristics.id::text")

        [
          build_predicate(provider, characteristics[:title], query),
          build_predicate(provider, id_expr, query)
        ]
      end
    end
  end
end
