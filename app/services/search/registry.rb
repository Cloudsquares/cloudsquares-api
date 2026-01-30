# frozen_string_literal: true

module Search
  # Registry — реестр дефиниций поиска по сущностям.
  class Registry
    DEFINITIONS = {
      properties: Search::Definitions::PropertiesDefinition.new,
      users: Search::Definitions::UsersDefinition.new,
      property_buy_requests: Search::Definitions::PropertyBuyRequestsDefinition.new,
      property_categories: Search::Definitions::PropertyCategoriesDefinition.new,
      property_characteristics: Search::Definitions::PropertyCharacteristicsDefinition.new,
      property_owners: Search::Definitions::PropertyOwnersDefinition.new
    }.freeze

    # Возвращает дефиницию поиска по ключу сущности.
    #
    # @param entity [String, Symbol]
    # @return [Search::Definitions::BaseDefinition]
    def self.definition_for(entity)
      DEFINITIONS.fetch(entity.to_sym)
    rescue KeyError
      raise ArgumentError, "Search definition not found for #{entity.inspect}"
    end
  end
end
