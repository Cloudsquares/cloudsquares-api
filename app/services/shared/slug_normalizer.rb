# frozen_string_literal: true

# Shared::SlugNormalizer — единая точка генерации «чистого» ASCII-slug ([a-z0-9-])
# из произвольного текста (включая кириллицу и казахский).
#
# Алгоритм:
# 1) Если доступна Babosa (String#to_slug), последовательно применяем трансформации:
#    - :kazakh (если определён кастомный транслитератор в initializers)
#    - :russian (или :cyrillic, если русского нет)
#    - :latin  (обязательно — «дожимает» результат до ASCII)
#    Затем .normalize → строка без диакритики/служебных символов.
# 2) Если Babosa недоступна (или дала пусто/не-ASCII) — fallback на
#    ActiveSupport::Inflector.transliterate.
# 3) Финальная чистка: всё, что не [a-z0-9], заменяем на '-', схлопываем повтор
#    дефисов и обрезаем края. Если строка пустая — возвращаем fallback.
#
# Почему именно так:
# — normalize(transliterations: [...]) в разных версиях Babosa ведёт себя по-разному;
#   пошаговые transliterate(:kk) → (:ru|:cyrillic) → :latin дают стабильный результат.
# — :latin обязателен, иначе могут остаться не-ASCII символы в некоторых окружениях.
#
# Как использовать:
#   Shared::SlugNormalizer.normalize("Частные дома") #=> "chastnye-doma"
#   Shared::SlugNormalizer.normalize("Қалдарыңыз қалай") #=> "qaldaryngyz-qalaj"
#
module Shared
  class SlugNormalizer
    # @param text [String, nil] произвольный текст
    # @param fallback [String] что вернуть, если после всех преобразований slug пустой
    # @return [String] «чистый» slug ([a-z0-9-])
    def self.normalize(text, fallback: "item")
      base = text.to_s
      return fallback if base.strip.empty?

      slug = if base.respond_to?(:to_slug)
               id = base.to_slug

               # Пошаговые трансформации: сначала специфичные, потом общие
               id = id.transliterate(:kazakh)   if defined?(Babosa::Transliterator::Kazakh)
               if defined?(Babosa::Transliterator::Russian)
                 id = id.transliterate(:russian)
               elsif defined?(Babosa::Transliterator::Cyrillic)
                 id = id.transliterate(:cyrillic)
               end
               id = id.transliterate(:latin)    # критично для ASCII

               candidate = id.normalize.to_s
               candidate = ActiveSupport::Inflector.transliterate(base).to_s if candidate.blank? || !candidate.ascii_only?
               candidate
      else
               # Нет Babosa — используем надёжный fallback из ActiveSupport
               ActiveSupport::Inflector.transliterate(base).to_s
      end

      cleaned = slug.to_s.downcase
                    .gsub(/[^a-z0-9]+/, "-")
                    .gsub(/\A-+|-+\z/, "")

      cleaned.presence || fallback
    end
  end
end
