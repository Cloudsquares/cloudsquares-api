# frozen_string_literal: true

module Search
  # Provider — базовый интерфейс поискового провайдера.
  class Provider
    # Применяет поиск к scope для указанной сущности.
    #
    # @param scope [ActiveRecord::Relation] базовый scope
    # @param definition [Search::Definitions::BaseDefinition] дефиниция сущности
    # @param query [String] нормализованный поисковый запрос
    # @param context [Search::Context] контекст запроса
    # @return [ActiveRecord::Relation]
    def apply(scope:, definition:, query:, context:)
      raise NotImplementedError, "Search provider must implement #apply"
    end

    # Строит предикат ILIKE для указанного выражения.
    #
    # @param expression [Arel::Nodes::Node] выражение/колонка
    # @param query [String] поисковый запрос
    # @return [Arel::Nodes::Node]
    def build_text_predicate(expression, query)
      raise NotImplementedError, "Search provider must implement #build_text_predicate"
    end
  end
end
