# frozen_string_literal: true

module Search
  module Definitions
    # BaseDefinition — базовый класс дефиниции поиска по сущности.
    class BaseDefinition
      # @return [Symbol] имя сущности в реестре
      attr_reader :entity

      # @param entity [Symbol] ключ сущности
      # @param distinct [Boolean] нужен ли DISTINCT для предотвращения дублей
      def initialize(entity:, distinct: false)
        @entity = entity
        @distinct = distinct
      end

      # Применяет joins и distinct к исходному scope.
      #
      # @param scope [ActiveRecord::Relation]
      # @param context [Search::Context]
      # @return [ActiveRecord::Relation]
      def apply(scope, context:)
        scoped = apply_joins(scope, context: context)
        @distinct ? scoped.distinct : scoped
      end

      # Возвращает набор Arel-предикатов для поискового запроса.
      #
      # @param query [String]
      # @param context [Search::Context]
      # @param provider [Search::Provider]
      # @return [Array<Arel::Nodes::Node>]
      def predicates(query:, context:, provider:)
        raise NotImplementedError, "Search definition must implement #predicates"
      end

      private

      # Добавляет необходимые JOIN-и для поиска.
      #
      # @param scope [ActiveRecord::Relation]
      # @param context [Search::Context]
      # @return [ActiveRecord::Relation]
      def apply_joins(scope, context:)
        scope
      end

      # Строит ILIKE-предикат через провайдера.
      #
      # @param provider [Search::Provider]
      # @param expression [Arel::Nodes::Node]
      # @param query [String]
      # @return [Arel::Nodes::Node]
      def build_predicate(provider, expression, query)
        provider.build_text_predicate(expression, query)
      end

      # Строит ILIKE-предикат для телефона с нормализацией.
      #
      # @param provider [Search::Provider]
      # @param expression [Arel::Nodes::Node]
      # @param query [String]
      # @return [Arel::Nodes::Node, nil]
      def build_phone_predicate(provider, expression, query)
        normalized = normalize_phone_query(query)
        return nil if normalized.blank?

        provider.build_text_predicate(expression, normalized)
      end

      # Нормализует телефонный запрос.
      #
      # @param query [String]
      # @return [String, nil]
      def normalize_phone_query(query)
        ::Shared::PhoneNormalizer.normalize(query)
      end

      # Создаёт выражение для склейки текстовых полей через "||".
      # Используется для совпадения с индексами на выражениях (IMMUTABLE).
      #
      # @param parts [Array<Arel::Nodes::Node>]
      # @return [Arel::Nodes::Node]
      def concat_ws(*parts)
        return Arel::Nodes.build_quoted("") if parts.empty?

        safe_parts = parts.map { |part| coalesce_blank(part) }

        safe_parts.reduce do |memo, part|
          with_space = Arel::Nodes::InfixOperation.new(
            "||",
            memo,
            Arel::Nodes.build_quoted(" ")
          )
          Arel::Nodes::InfixOperation.new("||", with_space, part)
        end
      end

      # Приводит nil к пустой строке, чтобы избежать NULL в concat.
      #
      # @param part [Arel::Nodes::Node]
      # @return [Arel::Nodes::NamedFunction]
      def coalesce_blank(part)
        Arel::Nodes::NamedFunction.new(
          "coalesce",
          [ part, Arel::Nodes.build_quoted("") ]
        )
      end
    end
  end
end
