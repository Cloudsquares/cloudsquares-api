# frozen_string_literal: true

module Search
  module Providers
    # PostgresTrigram — провайдер поиска через PostgreSQL + pg_trgm.
    class PostgresTrigram < Search::Provider
      # Применяет поиск к scope через ILIKE + pg_trgm индексы.
      #
      # @param scope [ActiveRecord::Relation] базовый scope
      # @param definition [Search::Definitions::BaseDefinition] дефиниция сущности
      # @param query [String] нормализованный поисковый запрос
      # @param context [Search::Context] контекст запроса
      # @return [ActiveRecord::Relation]
      def apply(scope:, definition:, query:, context:)
        prepared_scope = definition.apply(scope, context: context)
        predicates = definition.predicates(query: query, context: context, provider: self).compact
        return prepared_scope if predicates.empty?

        combined = predicates.reduce { |memo, predicate| memo.or(predicate) }
        prepared_scope.where(combined)
      end

      # Строит ILIKE-предикат с экранированием спецсимволов.
      #
      # @param expression [Arel::Nodes::Node] выражение/колонка
      # @param query [String] поисковый запрос
      # @return [Arel::Nodes::Node]
      def build_text_predicate(expression, query)
        safe_query = ActiveRecord::Base.sanitize_sql_like(query)
        pattern = "%#{safe_query}%"
        node = expression.is_a?(String) ? Arel.sql(expression) : expression
        Arel::Nodes::Matches.new(node, Arel::Nodes.build_quoted(pattern), nil, false)
      end
    end
  end
end
