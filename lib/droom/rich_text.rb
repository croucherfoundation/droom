module Droom
  module RichText
    module OptIn
      extend ActiveSupport::Concern

      included do
        class_attribute :rich_text_attribute_names, instance_writer: false, default: []
      end

      class_methods do
        def rich_text_attributes(*attributes)
          names = attributes.flatten.map(&:to_sym)
          return rich_text_attribute_names if names.empty?

          self.rich_text_attribute_names = (Array(rich_text_attribute_names) + names).uniq
        end

        def rich_text_attribute?(attribute_name)
          Array(rich_text_attribute_names).include?(attribute_name.to_sym)
        end
      end

      def sanitize_rich_text_attributes!
        self.class.rich_text_attribute_names.each do |attribute_name|
          next unless respond_to?(attribute_name)

          value = public_send(attribute_name)
          sanitized = Droom::SafeHtmlSanitizer.sanitize(value)
          next if value.to_s == sanitized

          public_send("#{attribute_name}=", sanitized)
        end
      end
    end
  end
end
