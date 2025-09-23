class RecaptchaService
  require "google/cloud/recaptcha_enterprise"

  THRESHOLD = 0.5

  class << self
    def verify(token:, action:)
      client  = build_client
      request = build_request(token)

      response = client.create_assessment(request)
      token_props = response.token_properties

      return log_invalid(token_props) unless token_props.valid
      return log_action_mismatch(token_props, action) unless token_props.action == action

      score = response.risk_analysis.score
      Rails.logger.info("reCAPTCHA score: #{score}")
      score >= THRESHOLD
    end

    private

    def build_client
      Google::Cloud::RecaptchaEnterprise.recaptcha_enterprise_service do |config|
        config.credentials = {
          "type"         => "service_account",
          "project_id"   => ENV.fetch("GCP_PROJECT_ID"),
          "private_key"  => ENV.fetch("GCP_PRIVATE_KEY").gsub("\\n", "\n"),
          "client_email" => ENV.fetch("GCP_CLIENT_EMAIL"),
          "token_uri"    => "https://oauth2.googleapis.com/token"
        }
      end
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

    def log_invalid(token_props)
      Rails.logger.warn "reCAPTCHA invalid: #{token_props.invalid_reason}"
      false
    end

    def log_action_mismatch(token_props, expected_action)
      Rails.logger.warn "reCAPTCHA action mismatch (expected #{expected_action}, got #{token_props.action})"
      false
    end
  end
end
