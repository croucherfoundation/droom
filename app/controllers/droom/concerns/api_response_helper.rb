module Droom::Concerns
  module ApiResponseHelper
    extend ActiveSupport::Concern

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

        response[:message] = message if message.present?

        # 1. Separate AMS-specific options from general custom payload options
        ams_options = options.extract!(:serializer, :each_serializer, :include, :meta, :meta_key)
        
        # 2. Force JSON:API to retain 'id', 'type', and 'attributes'
        ams_options[:adapter] = :json_api

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
  end
end