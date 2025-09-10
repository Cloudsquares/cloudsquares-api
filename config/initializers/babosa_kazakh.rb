# frozen_string_literal: true

# Кастомный транслитератор Babosa для казахского языка.
# Подключается автоматически при загрузке Rails, если gem "babosa" установлен.
#
# Зачем:
# — базовый Cyrilic-набор не покрывает казахские буквы (Ә, Ғ, Қ, Ң, Ө, Ұ, Ү, Һ, І).
# — мы дополняем его, чтобы слаги были читабельными и стабильными.
#
# Как добавить новый язык:
# 1) Создайте похожий файл в config/initializers/babosa_<язык>.rb
# 2) Опишите класс Babosa::Transliterator::<YourLang> < <База> (обычно < Cyrillic)
# 3) Укажите APPROXIMATIONS (Hash «символ → ASCII-приближение»)
# 4) В Shared::SlugNormalizer (если нужно) вставьте .transliterate(:your_lang) на нужную позицию.
#
begin
  require "babosa"

  module Babosa
    module Transliterator
      class Kazakh < Cyrillic
        APPROXIMATIONS = {
          "Ә" => "A",  "ә" => "a",
          "Ғ" => "G",  "ғ" => "g",
          "Қ" => "Q",  "қ" => "q",
          "Ң" => "Ng", "ң" => "ng",
          "Ө" => "O",  "ө" => "o",
          "Ұ" => "U",  "ұ" => "u",
          "Ү" => "U",  "ү" => "u",
          "Һ" => "H",  "һ" => "h",
          "І" => "I",  "і" => "i"
        }.freeze
      end
    end
  end
rescue LoadError
  # Если babosa не установлена — просто пропускаем. Fallback обработает Shared::SlugNormalizer.
end
