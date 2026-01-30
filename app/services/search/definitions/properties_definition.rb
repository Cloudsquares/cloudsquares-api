# frozen_string_literal: true

module Search
  module Definitions
    # PropertiesDefinition — правила поиска по объектам недвижимости.
    class PropertiesDefinition < BaseDefinition
      def initialize
        super(entity: :properties, distinct: true)
      end

      # Возвращает список предикатов для поиска по title, адресу и ФИО владельца.
      #
      # @param query [String]
      # @param context [Search::Context]
      # @param provider [Search::Provider]
      # @return [Array<Arel::Nodes::Node>]
      def predicates(query:, context:, provider:)
        properties = Property.arel_table
        locations = PropertyLocation.arel_table
        contacts = Contact.arel_table

        owner_name = concat_ws(contacts[:last_name], contacts[:first_name], contacts[:middle_name])
        address = concat_ws(
          locations[:country],
          locations[:region],
          locations[:city],
          locations[:street],
          locations[:house_number]
        )

        [
          build_predicate(provider, properties[:title], query),
          build_predicate(provider, owner_name, query),
          build_predicate(provider, address, query)
        ]
      end

      private

      # Добавляет join на адрес и владельцев для поиска.
      #
      # @param scope [ActiveRecord::Relation]
      # @param context [Search::Context]
      # @return [ActiveRecord::Relation]
      def apply_joins(scope, context:)
        scope.left_joins(:property_location, property_owners: :contact)
      end
    end
  end
end
