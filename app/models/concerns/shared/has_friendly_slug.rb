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

    # Глобальный список зарезервированных путей/слов (без учета регистра)
    RESERVED_SLUGS = %w[
      new edit index session login logout users admin
      stylesheets assets javascripts images
    ].freeze

    included do
      # Валидатор для запрета зарезервированных значений
      validate :slug_not_reserved
    end

    class_methods do
      # Подключение FriendlyId с нашим нормализатором
      def has_friendly_slug(source:, scope: nil, fallback: "item")
        extend FriendlyId

        opts = [ :slugged ]
        scope.present? ? friendly_id(source, use: opts + [ :scoped ], scope: scope) :
          friendly_id(source, use: opts)

        define_method(:should_generate_new_friendly_id?) do
          slug.blank? || (respond_to?(:"will_save_change_to_#{source}?") && public_send(:"will_save_change_to_#{source}?"))
        end

        define_method(:normalize_friendly_id) do |input|
          Shared::SlugNormalizer.normalize(input, fallback: fallback)
        end
      end
    end

    private

    def slug_not_reserved
      return if slug.blank?
      return unless RESERVED_SLUGS.include?(slug.to_s.downcase)

      errors.add(:slug, "зарезервировано и не может быть использовано")
    end
  end
end
