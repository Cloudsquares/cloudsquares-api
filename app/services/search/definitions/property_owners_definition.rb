# frozen_string_literal: true

module Search
  module Definitions
    # PropertyOwnersDefinition — правила поиска по владельцам недвижимости.
    class PropertyOwnersDefinition < BaseDefinition
      def initialize
        super(entity: :property_owners, distinct: false)
      end

      # Возвращает предикаты поиска по ФИО, телефону и email владельца.
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
          build_predicate(provider, contacts[:email], query),
          build_phone_predicate(provider, people[:normalized_phone], query)
        ].compact
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
