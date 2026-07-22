module Droom::Concerns
  module FlashMessageHelper
    extend ActiveSupport::Concern

    private

    # AJAX call
    def render_ajax_error(resource)
      if resource.respond_to?(:errors) && resource.errors.any?
        error_message = resource.errors.full_messages.to_sentence
        
      elsif resource.respond_to?(:metadata) && resource.metadata[:errors].present?
        error_message = resource.metadata[:errors].to_sentence
      end

      if error_message.blank?
        name = resource.respond_to?(:model_name) ? resource.model_name.human.downcase : "record"
        error_message = t("notifications.generic.save_failed", resource: name)
      end

      set_flash_headers(error_message, 'alert')
      head :unprocessable_entity
    end

    def set_success_flash_headers(resource, action)
      name = resource.respond_to?(:model_name) ? resource.model_name.human : "Record"
      message = case action
                when :create
                  t("notifications.generic.created", resource: name)
                when :update
                  t("notifications.generic.updated", resource: name)
                when :destroy
                  t("notifications.generic.deleted", resource: name)
                end
      set_flash_headers(message, 'notice')
    end

    def set_flash_headers(message, type)
      return unless message.present? && type.present?

      response.headers['X-Flash-Message'] = message
      response.headers['X-Flash-Type'] = type
    end

    # Flashes
    def set_create_notice(resource)
      name = resource.respond_to?(:model_name) ? resource.model_name.human : "Record"
      message = t("notifications.generic.created", resource: name)
      set_notice(message)
    end

    def set_update_notice(resource)
      name = resource.respond_to?(:model_name) ? resource.model_name.human : "Record"
      message = t("notifications.generic.updated", resource: name)
      set_notice(message)
    end

    def set_delete_notice(resource)
      name = resource.respond_to?(:model_name) ? resource.model_name.human : "Record"
      message = t("notifications.generic.deleted", resource: name)
      set_notice(message)
    end

    def set_notice(message)
      flash[:notice] = message if message.present?
    end

    def set_alert(resource = nil, message: nil)
      errors = message

      # Backward compatibility: allow set_alert("custom message").
      if errors.blank? && resource.is_a?(String)
        errors = resource
      end

      if errors.blank? && resource.respond_to?(:errors)
        errors = resource.errors.full_messages.to_sentence
      end

      if errors.blank?
        resource_name = resource.respond_to?(:model_name) ? resource.model_name.human.downcase : "record"
        errors = t("notifications.generic.save_failed", resource: resource_name)
      end

      flash[:alert] = errors if errors.present?
    end
  end
end