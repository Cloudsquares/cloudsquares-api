# frozen_string_literal: true

module Search
  module Definitions
    # PropertyCategoriesDefinition — правила поиска по категориям недвижимости.
    class PropertyCategoriesDefinition < BaseDefinition
      def initialize
        super(entity: :property_categories, distinct: false)
      end

      # Возвращает предикаты поиска по title и id (UUID как текст).
      #
      # @param query [String]
      # @param context [Search::Context]
      # @param provider [Search::Provider]
      # @return [Array<Arel::Nodes::Node>]
      def predicates(query:, context:, provider:)
        categories = PropertyCategory.arel_table
        id_expr = Arel.sql("property_categories.id::text")

        [
          build_predicate(provider, categories[:title], query),
          build_predicate(provider, id_expr, query)
        ]
      end
    end
  end
end
