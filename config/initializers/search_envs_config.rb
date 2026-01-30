# frozen_string_literal: true

# Настройки поиска: провайдер, лимиты запроса и выдачи.
Rails.application.config.x.search ||= ActiveSupport::OrderedOptions.new
Rails.application.config.x.search[:provider] = ENV.fetch("SEARCH_PROVIDER", "postgres").to_s
Rails.application.config.x.search[:query_max_length] = ENV.fetch("SEARCH_QUERY_MAX_LENGTH", "256").to_i
Rails.application.config.x.search[:max_results] = ENV.fetch("SEARCH_MAX_RESULTS", "500").to_i
