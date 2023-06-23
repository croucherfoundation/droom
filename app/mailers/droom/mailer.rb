module Droom
  class Mailer < ActionMailer::Base
    layout Droom.email_layout
    default from: '"Hong Kong Foundations Exchange" <info@hkfx.org>'

    def org_confirmation(organisation)
      @organisation = organisation
      @user = organisation.owner
      @subject = I18n.t("registration.confirmation_subject", name: organisation.name)
      @email = Rails.env.produciton? ? @user.email : Settings.email.sandbox
      mail(to: @email, subject: @subject)
    end

    def org_notification(organisation, admin, noti_type)
      @organisation = organisation
      @admin = admin
      @user = organisation.owner
      @noti_type = noti_type
      @subject = @noti_type == :created ? I18n.t("registration.notification_subject", name: organisation.name) : I18n.t("withdraw.notification_subject")
      @email = Rails.env.produciton? ? @admin.email : Settings.email.sandbox
      mail(to: @email, subject: @subject)
    end

    def org_welcome(organisation, token)
      @organisation = organisation
      @user = organisation.owner
      @token = token
      @subject = I18n.t("registration.welcome_subject", name: organisation.name)
      @email = Rails.env.produciton? ? @user.email : Settings.email.sandbox
      mail(to: @email, subject: @subject)
    end

  end
end