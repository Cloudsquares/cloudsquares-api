# frozen_string_literal: true

module Search
  module Definitions
    # UsersDefinition — правила поиска по сотрудникам агентства.
    class UsersDefinition < BaseDefinition
      def initialize
        super(entity: :users, distinct: true)
      end

      # Возвращает предикаты поиска по ФИО, телефону и email.
      #
      # @param query [String]
      # @param context [Search::Context]
      # @param provider [Search::Provider]
      # @return [Array<Arel::Nodes::Node>]
      def predicates(query:, context:, provider:)
        users = User.arel_table
        people = Person.arel_table
        contacts = Contact.arel_table
        profiles = UserProfile.arel_table

        name_expr = concat_ws(contacts[:last_name], contacts[:first_name], contacts[:middle_name])
        profile_name_expr = concat_ws(
          profiles[:last_name],
          profiles[:first_name],
          profiles[:middle_name]
        )
        agency_guard = context.agency_id ? contacts[:agency_id].eq(context.agency_id) : nil

        predicates = [
          build_predicate(provider, users[:email], query),
          build_predicate(provider, people[:normalized_phone], query),
          build_predicate(provider, profile_name_expr, query)
        ]

        if agency_guard
          predicates << agency_guard.and(build_predicate(provider, name_expr, query))
          predicates << agency_guard.and(build_predicate(provider, contacts[:email], query))
        end

        predicates
      end

      private

      # Добавляет join на person и contact для поиска.
      #
      # @param scope [ActiveRecord::Relation]
      # @param context [Search::Context]
      # @return [ActiveRecord::Relation]
      def apply_joins(scope, context:)
        scope.left_joins(:profile, person: :contacts)
      end
    end
  end
end
