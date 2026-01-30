# frozen_string_literal: true

module Search
  module Definitions
    # PropertyBuyRequestsDefinition — правила поиска по заявкам на покупку.
    class PropertyBuyRequestsDefinition < BaseDefinition
      def initialize
        super(entity: :property_buy_requests, distinct: false)
      end

      # Возвращает предикаты поиска по ФИО и телефону контакта.
      #
      # @param query [String]
      # @param context [Search::Context]
      # @param provider [Search::Provider]
      # @return [Array<Arel::Nodes::Node>]
      def predicates(query:, context:, provider:)
        contacts = Contact.arel_table
        people = Person.arel_table

        name_expr = concat_ws(contacts[:last_name], contacts[:first_name], contacts[:middle_name])

        [
          build_predicate(provider, name_expr, query),
          build_predicate(provider, people[:normalized_phone], query)
        ]
      end

      private

      # Добавляет join на contact/person для поиска.
      #
      # @param scope [ActiveRecord::Relation]
      # @param context [Search::Context]
      # @return [ActiveRecord::Relation]
      def apply_joins(scope, context:)
        scope.left_joins(contact: :person)
      end
    end
  end
end
