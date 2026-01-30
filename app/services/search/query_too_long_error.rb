# frozen_string_literal: true

module Search
  # QueryTooLongError — исключение для слишком длинного поискового запроса.
  #
  # Используется для возврата 400 Bad Request при превышении лимита.
  class QueryTooLongError < StandardError
    # @return [Integer] максимально допустимая длина запроса
    attr_reader :max_length

    # @param max_length [Integer] максимально допустимая длина запроса
    def initialize(max_length)
      @max_length = max_length
      super("Поисковый запрос превышает допустимую длину: #{max_length}")
    end
  end
end
