module Droom::Concerns
  module ApiResponseHelper
    extend ActiveSupport::Concern

    private

    def render_api_success(message:, status: :ok, **payload)
      render json: { success: true, message: message }.merge(payload), status: status
    end

    def render_api_error(errors:, status: :unprocessable_entity, **payload)
      render json: { success: false, errors: normalize_api_errors(errors) }.merge(payload), status: status
    end

    def normalize_api_errors(errors)
      case errors
      when Array
        errors.compact.map(&:to_s)
      when nil
        []
      else
        [errors.to_s]
      end
    end
  end
end