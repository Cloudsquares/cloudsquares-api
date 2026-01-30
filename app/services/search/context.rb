# frozen_string_literal: true

module Search
  # Context — переносит текущий контекст (агентство/пользователь) в слой поиска.
  Context = Struct.new(:agency, :user, keyword_init: true) do
    # @return [String, nil] идентификатор агентства
    def agency_id
      agency&.id
    end
  end
end
