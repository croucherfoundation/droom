module Droom::Concerns
  module FlashMessageHelper
    extend ActiveSupport::Concern

    private

    def set_notice(message)
      flash[:notice] = message if message.present?
    end

    def set_alert(errors)
      message = normalize_alert_message(errors)
      flash[:alert] = message if message.present?
    end

    def normalize_alert_message(errors)
      case errors
      when Array
        errors.compact.map(&:to_s).reject(&:empty?).join(". ")
      when nil
        nil
      else
        errors.to_s
      end
    end
  end
end