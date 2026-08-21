module Droom
  # Shared rich-text sanitizer for host apps.
  # Keep usage opt-in at model/service layer in each app.
  module SafeHtmlSanitizer
    ALLOWED_TAGS = %w[
      p br strong em u ul ol li blockquote a
      h2 h3 h4
    ].freeze

    ALLOWED_ATTRIBUTES = %w[
      href rel target
    ].freeze

    ALLOWED_PROTOCOLS = %w[
      http https mailto
    ].freeze

    module_function

    def sanitize(value)
      return "" if value.nil?

      sanitized = sanitizer.sanitize(
        value.to_s,
        tags: ALLOWED_TAGS,
        attributes: ALLOWED_ATTRIBUTES
      )

      enforce_link_protocols(sanitized)
    end

    def allowed_tags
      ALLOWED_TAGS
    end

    def allowed_attributes
      ALLOWED_ATTRIBUTES
    end

    # private

    def sanitizer
      @sanitizer ||= Rails::Html::SafeListSanitizer.new
    end

    def enforce_link_protocols(html)
      fragment = Loofah.fragment(html)
      fragment.css("a[href]").each do |node|
        href = node["href"]
        next if href.nil? || href.strip.empty?

        protocol = href.to_s.strip.downcase.split(":", 2).first
        node.remove_attribute("href") unless ALLOWED_PROTOCOLS.include?(protocol)
      end
      fragment.to_html
    end

    # Removes unsafe link protocols while preserving allowed rich-text markup.
    # This runs after tag/attribute allowlist sanitization.
  end
end
