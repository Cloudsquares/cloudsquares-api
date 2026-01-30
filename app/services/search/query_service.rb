# frozen_string_literal: true

module Search
  # QueryService — применяет поиск к ActiveRecord scope по правилам сущности.
  class QueryService
    PROVIDERS = {
      "postgres" => Search::Providers::PostgresTrigram,
      "postgres_trigram" => Search::Providers::PostgresTrigram
    }.freeze

    # @param entity [String, Symbol] ключ сущности
    # @param scope [ActiveRecord::Relation] исходный scope
    # @param query [String, nil] raw запрос из params
    # @param context [Search::Context, nil] контекст запроса
    # @param limit [Integer, nil] ограничение количества результатов
    def initialize(entity:, scope:, query:, context: nil, limit: nil)
      @entity = entity.to_sym
      @scope = scope
      @query = query
      @context = context || Search::Context.new(agency: Current.agency, user: Current.user)
      @limit = limit
    end

    # @param args [Hash]
    # @return [ActiveRecord::Relation]
    def self.call(**args)
      new(**args).call
    end

    # Применяет поиск и возвращает обновлённый scope.
    #
    # @return [ActiveRecord::Relation]
    def call
      parsed = Search::QueryParser.parse(@query)
      return @scope if parsed.nil?

      log_query(parsed)

      definition = Search::Registry.definition_for(@entity)
      provider = provider_for

      result = provider.apply(scope: @scope, definition: definition, query: parsed.query, context: @context)
      apply_limit(result)
    end

    private

    # Возвращает провайдера поиска по конфигу.
    #
    # @return [Search::Provider]
    def provider_for
      provider_class = PROVIDERS[SearchConfig.provider.to_s]
      return provider_class.new if provider_class

      raise ArgumentError, "Unknown search provider: #{SearchConfig.provider.inspect}"
    end

    # Применяет лимит результатов при необходимости.
    #
    # @param scope [ActiveRecord::Relation]
    # @return [ActiveRecord::Relation]
    def apply_limit(scope)
      return scope if @limit.blank?
      return scope if @limit.to_i <= 0

      scope.limit(@limit.to_i)
    end

    # Логирует запрос в безопасном виде (без PII).
    #
    # @param parsed [Search::QueryParser::Result]
    # @return [void]
    def log_query(parsed)
      Rails.logger.info(
        "[Search] entity=#{@entity} agency_id=#{@context.agency_id} q=#{parsed.masked_query}"
      )
    end
  end
end
