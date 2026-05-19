module Droom
  class ShareMailer < ActionMailer::Base
    layout Droom.email_layout
    default from: %{'Croucher Foundation' <#{Droom.email_from}>}

    before_action :set_ses_configuration_set
    after_action :prevent_delivery_in_nonproduction

    def share_notification(share)
      @share = share
      @recipient = share.shared_with
      @sharer = share.shared_by
      @shareable = share.shareable
      @subject = "#{@sharer.name} shared a #{@shareable.class.name.demodulize.downcase} with you: #{@shareable.name}"

      if Rails.env.production?
        @email = @recipient.email
      else
        @email = Settings.email.sandbox
      end

      mail(to: @email, subject: @subject)
    end

    private
    
    def set_ses_configuration_set
      headers["X-SES-CONFIGURATION-SET"] = "cdr-mailer-events-#{Rails.env}"
    end

    def prevent_delivery_in_nonproduction
      unless Rails.env.production?
        unless FeatureFlag.enabled?('email-service-feature', @recipient)
          puts "⛔️ Disabled Email Delivery!"
          mail.perform_deliveries = false
        end
      end
    end
  end
end
