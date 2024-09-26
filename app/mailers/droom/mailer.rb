module Droom
  class Mailer < ActionMailer::Base
    layout Droom.email_layout
    default from: %{'Croucher Foundation' <#{Droom.email_from}>}

    # after_action :prevent_delivery_in_nonproduction

    def org_confirmation(organisation)
      @organisation = organisation
      @user = organisation.owner
      @subject = I18n.t("registration.confirmation_subject", name: organisation.name)

      if Rails.env.production?
        @email = @user.email
      else
        @email = Settings.email.sandbox
      end

      mail(to: @email, subject: @subject)
    end

    def org_notification(organisation, admin)
      @organisation = organisation
      @admin = admin
      @user = organisation.owner
      @subject = I18n.t("registration.notification_subject", name: organisation.name)

      if Rails.env.production?
        @email = @admin.email
      else
        @email = Settings.email.sandbox
      end

      mail(to: @email, subject: @subject)
    end

    def org_welcome(organisation, token)
      @organisation = organisation
      @user = organisation.owner
      @token = token
      @subject = I18n.t("registration.welcome_subject", name: organisation.name)

      if Rails.env.production?
        @email = @user.email
      else
        @email = Settings.email.sandbox
      end

      mail(to: @email, subject: @subject)
    end

    def otp_verification(user)
      @user = user
      @email = Rails.env.production? ? @user.email : Settings.email.sandbox
      @subject = I18n.t("subjects.user.otp_verification")

      mail(to: @email, subject: @subject)
    end

    private

    def prevent_delivery_in_nonproduction
      unless Rails.env.production?
        unless FeatureFlag.enabled?('email-service-feature', @user)
          puts "⛔️ Disabed Email Delivery!"
          mail.perform_deliveries = false
        end
      end
    end

  end
end
