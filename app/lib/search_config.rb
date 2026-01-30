# frozen_string_literal: true

# SearchConfig — обёртка над Rails.application.config.x.search
# для безопасного доступа к настройкам поиска.
class SearchConfig
  class << self
    # Возвращает имя провайдера поиска (например, "postgres").
    #
    # @return [String]
    def provider
      config[:provider]
    end

    # Возвращает максимальную длину поискового запроса.
    #
    # @return [Integer]
    def query_max_length
      config[:query_max_length]
    end

    # Возвращает ограничение количества результатов для непагинированных выдач.
    #
    # @return [Integer]
    def max_results
      config[:max_results]
    end

    private

    # @return [ActiveSupport::OrderedOptions]
    def config
      Rails.application.config.x.search
    end
  end
end
