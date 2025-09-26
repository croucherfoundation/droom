class RecaptchaService
  require "google/cloud/recaptcha_enterprise"

  THRESHOLD = 0.7

  class << self
    def verify(token:, action:)
      response = recaptcha_service.create_assessment(build_request(token))
      token_props = response.token_properties

      return handle_invalid(token_props) unless token_props.valid
      return handle_action_mismatch(token_props, action) unless token_props.action == action

      score = response.risk_analysis.score.to_f
      Rails.logger.info("[reCAPTCHA] score=#{score} action=#{action}")

      score > THRESHOLD
    rescue => e
      Rails.logger.error("[reCAPTCHA] Verification error: #{e.class} - #{e.message}")
      false
    end

    private

    def recaptcha_service
      @recaptcha_service ||= Google::Cloud::RecaptchaEnterprise.recaptcha_enterprise_service do |config|
        config.credentials = service_account_credentials
      end
    end

    def service_account_credentials
      {
        "type"         => "service_account",
        "project_id"   => ENV.fetch("GCP_PROJECT_ID"),
        "private_key"  => ENV.fetch("GCP_PRIVATE_KEY").gsub("\\n", "\n"),
        "client_email" => ENV.fetch("GCP_CLIENT_EMAIL"),
        "token_uri"    => "https://oauth2.googleapis.com/token"
      }
    end

    def build_request(token)
      {
        parent: "projects/#{ENV.fetch('GCP_PROJECT_ID')}",
        assessment: {
          event: {
            site_key: ENV.fetch("RECAPTCHA_SITE_KEY"),
            token: token
          }
        }
      }
    end

    def handle_invalid(token_props)
      Rails.logger.warn("[reCAPTCHA] invalid token: reason=#{token_props.invalid_reason}")
      false
    end

    def handle_action_mismatch(token_props, expected_action)
      Rails.logger.warn("[reCAPTCHA] action mismatch: expected=#{expected_action}, got=#{token_props.action}")
      false
    end
  end
end
