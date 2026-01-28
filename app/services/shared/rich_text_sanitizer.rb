# frozen_string_literal: true

# Typedoc:
# @class Shared::RichTextSanitizer
# @description
#   Санитайзер для безопасного HTML из TipTap. Работает по allow-list:
#   - Разрешённые теги и атрибуты перечислены явно;
#   - Любые инлайновые стили и on* обработчики удаляются;
#   - Ссылки нормализуются: запрещаем небезопасные протоколы,
#     для target="_blank" дописываем rel="noopener noreferrer nofollow".
#
# @example
#   html = Shared::RichTextSanitizer.sanitize(params[:property][:description])
#
# @return [String] Очищенный безопасный HTML (или пустая строка, если вход пустой)
#
module Shared
  class RichTextSanitizer
    # Базовый санитайзер (из rails-html-sanitizer)
    SafeList = Rails::Html::WhiteListSanitizer.new

    # Разрешаем только используемые в TipTap блоки и инлайны (без <img>).
    # TODO: Рассмотреть поддержку <img> после согласования правил безопасности.
    ALLOWED_TAGS = %w[
      p br strong em u s code pre blockquote ul ol li h1 h2 h3 h4 hr sup sub mark a
      div span label input
    ].freeze

    # Разрешённые атрибуты. Inline-стили допускаем только с ограниченным allow-list.
    # data-* используются TipTap (task list, highlight), ссылки — href/target/rel/title.
    ALLOWED_ATTRIBUTES = %w[
      href target rel title style data-color data-type data-checked type checked disabled
    ].freeze

    # Разрешённые протоколы в href (mailto/tel по желанию – оставлены).
    ALLOWED_PROTOCOLS = %w[http https mailto tel].freeze

    # Разрешённые значения text-align.
    ALLOWED_TEXT_ALIGN = %w[left right center justify].freeze

    # Разрешённые значения data-type для TipTap узлов.
    ALLOWED_DATA_TYPES = %w[taskList taskItem horizontalRule image-upload].freeze

    # Разрешённые значения data-checked.
    ALLOWED_CHECKED_VALUES = %w[true false].freeze

    # Разрешённые input-типы для TaskList.
    ALLOWED_INPUT_TYPES = %w[checkbox].freeze

    # Разрешённые значения цветов для background-color.
    ALLOWED_COLOR_KEYWORDS = %w[transparent currentColor].freeze

    HEX_COLOR_REGEX = /\A#(?:[0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8})\z/i
    CSS_VAR_REGEX = /\Avar\(--[a-z0-9-]+\)\z/i
    RGB_COLOR_REGEX = /\Argb\(\s*\d{1,3}\s*,\s*\d{1,3}\s*,\s*\d{1,3}\s*\)\z/i
    RGBA_COLOR_REGEX =
      /\Argba\(\s*\d{1,3}\s*,\s*\d{1,3}\s*,\s*\d{1,3}\s*,\s*(?:0|1|0?\.\d+)\s*\)\z/i
    HSL_COLOR_REGEX = /\Ahsl\(\s*\d{1,3}\s*,\s*\d{1,3}%\s*,\s*\d{1,3}%\s*\)\z/i
    HSLA_COLOR_REGEX =
      /\Ahsla\(\s*\d{1,3}\s*,\s*\d{1,3}%\s*,\s*\d{1,3}%\s*,\s*(?:0|1|0?\.\d+)\s*\)\z/i

    class << self
      # Очищает HTML по allow-list и нормализует ссылки.
      #
      # @param [String, nil] html Входной HTML
      # @return [String] Очищенный HTML ("" для nil/пустых входов)
      def sanitize(html)
        return "" if html.blank?

        cleaned = SafeList.sanitize(
          html.to_s,
          tags: ALLOWED_TAGS,
          attributes: ALLOWED_ATTRIBUTES,
        )

        # Пост-обработка ссылок: фильтрация протоколов, rel для _blank
        cleaned = postprocess_links(cleaned)

        # Пост-обработка inline-стилей и highlight-цветов
        sanitize_inline_styles(cleaned)
      end

      private

      # Пробегаемся по ссылкам и:
      # 1) убираем опасные протоколы (javascript:, data:, vbscript:)
      # 2) добавляем rel для target="_blank"
      #
      # @param [String] html
      # @return [String]
      def postprocess_links(html)
        # Loofah входит транзитивно через rails-html-sanitizer
        doc = Loofah.fragment(html)

        doc.css("a").each do |a|
          href = a["href"].to_s

          # Руби URI.parse понимает и mailto/tel; некорректные ссылки — убираем href
          begin
            uri = URI.parse(href)
          rescue URI::InvalidURIError
            a.remove_attribute("href")
            next
          end

          # Протокол не в allow-list -> убираем href
          if uri.scheme && !ALLOWED_PROTOCOLS.include?(uri.scheme.downcase)
            a.remove_attribute("href")
          end

          # target="_blank" -> гарантируем rel-набор
          if a["target"].to_s.downcase == "_blank"
            rel = a["rel"].to_s.split(/\s+/)
            %w[noopener noreferrer nofollow].each { |t| rel << t unless rel.include?(t) }
            a["rel"] = rel.uniq.join(" ")
          end
        end

        # Вырезаем любые on* атрибуты, если вдруг проскочили
        doc.traverse do |node|
          next unless node.element?
          node.attribute_nodes.select { |attr| attr.name.downcase.start_with?("on") }.each(&:remove)
        end

        doc.to_html
      end

      # Санитизирует inline-стили и приводит их к строгому allow-list.
      # Допустимые свойства: text-align, background-color.
      #
      # @param [String] html
      # @return [String]
      def sanitize_inline_styles(html)
        doc = Loofah.fragment(html)

        doc.traverse do |node|
          next unless node.element?

          sanitize_node_styles(node)
        end

        doc.to_html
      end

      # Очищает inline-стили и нормализует TipTap-атрибуты.
      #
      # @param [Loofah::HTML5::Node] node
      # @return [void]
      def sanitize_node_styles(node)
        sanitized_style = sanitize_style_value(node["style"])

        if sanitized_style.present?
          node["style"] = sanitized_style
        else
          node.remove_attribute("style")
        end

        sanitize_highlight_mark(node)
        sanitize_data_attributes(node)
        sanitize_task_list_input(node)
      end

      # Нормализует highlight-цвета для <mark>.
      #
      # @param [Loofah::HTML5::Node] node
      # @return [void]
      def sanitize_highlight_mark(node)
        return unless node.name == "mark"

        data_color = node["data-color"]
        sanitized_color = sanitize_color(data_color)

        if sanitized_color.present?
          node["data-color"] = sanitized_color

          unless node["style"].to_s.match?(/background-color/i)
            node["style"] =
              [ node["style"], "background-color: #{sanitized_color}" ]
                .reject(&:blank?)
                .join("; ")
          end
        else
          node.remove_attribute("data-color")
        end
      end

      # Ограничивает data-* атрибуты, необходимые для TipTap.
      #
      # @param [Loofah::HTML5::Node] node
      # @return [void]
      def sanitize_data_attributes(node)
        data_type = node["data-type"].to_s

        if data_type.present? && !ALLOWED_DATA_TYPES.include?(data_type)
          node.remove_attribute("data-type")
        end

        data_checked = node["data-checked"].to_s.downcase

        if data_checked.present? && !ALLOWED_CHECKED_VALUES.include?(data_checked)
          node.remove_attribute("data-checked")
        elsif data_checked.present?
          node["data-checked"] = data_checked
        end
      end

      # Нормализует input для TaskList.
      #
      # @param [Loofah::HTML5::Node] node
      # @return [void]
      def sanitize_task_list_input(node)
        return unless node.name == "input"

        input_type = node["type"].to_s.downcase
        node["type"] = "checkbox" unless ALLOWED_INPUT_TYPES.include?(input_type)

        node.attribute_nodes.each do |attr|
          next if %w[type checked disabled].include?(attr.name)

          attr.remove
        end
      end

      # Разбирает inline-стиль и оставляет только разрешённые декларации.
      #
      # @param [String, nil] style_value
      # @return [String]
      def sanitize_style_value(style_value)
        return "" if style_value.blank?

        declarations = style_value.to_s.split(";")

        sanitized = declarations.filter_map do |declaration|
          property, value = declaration.split(":", 2).map(&:strip)
          next if property.blank? || value.blank?

          normalized_property = property.downcase

          case normalized_property
          when "text-align"
            align_value = value.downcase
            next unless ALLOWED_TEXT_ALIGN.include?(align_value)

            "text-align: #{align_value}"
          when "background-color"
            color_value = sanitize_color(value)
            next if color_value.blank?

            "background-color: #{color_value}"
          end
        end

        sanitized.join("; ")
      end

      # Проверяет и нормализует значения цветов.
      #
      # @param [String, nil] value
      # @return [String]
      def sanitize_color(value)
        return "" if value.blank?

        normalized = value.to_s.strip
        normalized_downcase = normalized.downcase

        return normalized_downcase if ALLOWED_COLOR_KEYWORDS.include?(normalized_downcase)
        return normalized_downcase if HEX_COLOR_REGEX.match?(normalized_downcase)
        return normalized if CSS_VAR_REGEX.match?(normalized)
        return normalized_downcase if RGB_COLOR_REGEX.match?(normalized_downcase)
        return normalized_downcase if RGBA_COLOR_REGEX.match?(normalized_downcase)
        return normalized_downcase if HSL_COLOR_REGEX.match?(normalized_downcase)
        return normalized_downcase if HSLA_COLOR_REGEX.match?(normalized_downcase)

        ""
      end
    end
  end
end
