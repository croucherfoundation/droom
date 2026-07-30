module Droom::Concerns
  module ApiResponseHelper
    extend ActiveSupport::Concern

    included do
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from StandardError, with: :blew_up
      rescue_from Droom::DroomError, with: :blew_up
      rescue_from Droom::AccessDenied, with: :not_allowed
    end

    private

    def render_api_success(message: nil, status: :ok, resource: nil, **options)
      status = :created if action_name == 'create'
      response = { success: true }
      
      if resource
        resource_name = resource.model_name.human
        message ||= {
          'create'  => t('notifications.generic.created', resource: resource_name),
          'update'  => t('notifications.generic.updated', resource: resource_name),
          'destroy' => t('notifications.generic.deleted', resource: resource_name)
        }[action_name]

        # 1. Separate AMS-specific options from general custom payload options
        ams_options = options.extract!(:serializer, :each_serializer, :include, :meta, :meta_key)
        
        # 2. Force JSON:API to retain 'id', 'type', and 'attributes'
        ams_options[:adapter] = :json_api
        ams_options[:serialization_context] ||= ActiveModelSerializers::SerializationContext.new(request)

        # 3. Serialize the resource
        serialized_payload = ActiveModelSerializers::SerializableResource.new(
          resource, 
          ams_options
        ).as_json

        # 4. Extract data to prevent the double "data" wrapper
        response[:data] = serialized_payload[:data]
        
        # Safely retain AMS metadata if you use pagination or custom meta keys
        response[:meta] = serialized_payload[:meta] if serialized_payload.key?(:meta)
      end

      # Return explicit message even when no resource is provided
      response[:message] = message if message.present?

      # Merge any remaining custom options (like extra root-level keys) and render
      render json: response.merge(options), status: status
    end

    def render_api_error(errors:, status: :unprocessable_entity, **payload)
      render json: { success: false, errors: normalize_api_errors(errors) }.merge(payload), status: status
    end

    def normalize_api_errors(errors)
      case errors
      when ActiveModel::Errors
        # Natively handles Rails validation errors (e.g., @address.errors)
        errors.full_messages
      when Array
        errors.compact.map(&:to_s)
      when String
        [errors]
      when nil
        []
      else
        [errors.to_s]
      end
    end

    def not_found(exception)    
      name = exception.model.demodulize.underscore.humanize rescue name_from_controller.singularize.humanize
      message = t('notifications.generic.not_found', resource: name)
      render_api_error(errors: message, status: :not_found)
    end

    def not_authorized(exception)
      render_api_error(errors: t('notifications.authentication.access_denied'), status: :forbidden)
    end

    def not_allowed(exception)
      render_api_error(errors: t('notifications.authentication.permission_denied'), status: :forbidden)
    end

    def blew_up(exception)
      Honeybadger.notify(exception)
      Rails.logger.error "API Error #500: #{exception.message}\n#{exception.backtrace.join("\n")}"
      render_api_error(errors: t('notifications.generic.unexpected_error'), status: :internal_server_error)
    end

  end
end