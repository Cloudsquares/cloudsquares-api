# frozen_string_literal: true

module Search
  # QueryParser — нормализует поисковый запрос и применяет PII-маскирование.
  class QueryParser
    Result = Struct.new(:query, :masked_query, keyword_init: true)

    EMAIL_REGEX = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i.freeze
    PHONE_REGEX = /\b\+?\d[\d\s\-\(\)]{6,}\d\b/.freeze

    class << self
      # Нормализует запрос и возвращает его с маскированием PII.
      #
      # @param raw [String, nil] исходный запрос
      # @return [Result, nil] нормализованный и замаскированный запрос
      # @raise [Search::QueryTooLongError] если превышен лимит длины запроса
      def parse(raw)
        return nil if raw.nil?

        normalized = raw.to_s.strip
        normalized = normalized.squish
        return nil if normalized.blank?

        max_length = SearchConfig.query_max_length
        if max_length.present? && normalized.length > max_length
          raise Search::QueryTooLongError, max_length
        end

        Result.new(query: normalized, masked_query: mask_pii(normalized))
      end

      # Маскирует email и телефон в строке запроса.
      #
      # @param query [String] нормализованный запрос
      # @return [String] безопасная строка для логов
      def mask_pii(query)
        query
          .gsub(EMAIL_REGEX, "[email]")
          .gsub(PHONE_REGEX, "[phone]")
      end
    end
  end
end
