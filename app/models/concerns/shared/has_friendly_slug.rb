# frozen_string_literal: true

# Shared::HasFriendlySlug — concern для моделей, которым нужны «дружелюбные» slug'и.
#
# Что делает:
# - Подключает FriendlyId с режимом :slugged (и :scoped при необходимости).
# - Контролирует момент регенерации слуга (когда пустой или изменилось поле-источник).
# - Делегирует нормализацию слуга в Shared::SlugNormalizer (единая точка правды).
#
# Использование в модели:
#   class PropertyCategory < ApplicationRecord
#     include Shared::HasFriendlySlug
#     has_friendly_slug source: :title, scope: :agency_id, fallback: "item"
#     ...
#   end
#
# Параметры:
#   source:   [Symbol] метод/атрибут-источник (например, :title)
#   scope:    [Symbol, nil] поле для «скоупнутой» уникальности FriendlyId (например, :agency_id)
#   fallback: [String] запасной slug, если после нормализации строка пустая
#
require "friendly_id"

module Shared
  module HasFriendlySlug
    extend ActiveSupport::Concern

    class_methods do
      def has_friendly_slug(source:, scope: nil, fallback: "item")
        extend FriendlyId

        options = [:slugged]
        scope.present? ? friendly_id(source, use: options + [:scoped], scope: scope)
          : friendly_id(source, use: options)

        define_method(:should_generate_new_friendly_id?) do
          # Генерируем slug при первом сохранении или когда изменилось поле-источник
          changed = public_send(:"will_save_change_to_#{source}?") rescue false
          slug.blank? || changed
        end

        define_method(:normalize_friendly_id) do |input|
          Shared::SlugNormalizer.normalize(input, fallback: fallback)
        end
      end
    end
  end
end
