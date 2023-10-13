module Droom
  class Mailer < ActionMailer::Base
    layout Droom.email_layout
    before_action :bcc_email
    default from: '"Hong Kong Foundations Exchange" <info@hkfx.org>'

    def org_confirmation(organisation)
      @organisation = organisation
      @user = organisation.owner
      @subject = I18n.t("registration.confirmation_subject", name: organisation.name)
      @email = Rails.env.production? ? @user.email : Settings.email.sandbox
      mail(to: @email, bcc: bcc_email, subject: @subject)
    end

    def org_notification(organisation, admin, noti_type)
      @organisation = organisation
      @admin = admin
      @user = organisation.owner
      @noti_type = noti_type
      @subject = @noti_type == :created ? I18n.t("registration.notification_subject", name: organisation.name) : I18n.t("withdraw.notification_subject")
      @email = Rails.env.production? ? @admin.email : Settings.email.sandbox
      mail(to: @email, bcc: bcc_email,subject: @subject)
    end

    def org_welcome(organisation, token)
      @organisation = organisation
      @user = organisation.owner
      @token = token
      @subject = I18n.t("registration.welcome_subject", name: organisation.name)
      @email = Rails.env.production? ? @user.email : Settings.email.sandbox
      mail(to: @email, bcc: bcc_email, subject: @subject)
    end

    private

    def bcc_email
      Rails.env.production? ? ENV['CC_EMAIL'] : ['dev.zinmoe@gmail.com','thiha.devops@gmail.com']
    end

  end
end