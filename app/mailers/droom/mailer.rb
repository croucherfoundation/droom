module Droom
  class Mailer < ActionMailer::Base
    layout Settings.email.layout
    default from: Settings.email.from

    def org_confirmation(organisation)
      @organisation = organisation
      @user = organisation.owner
      @subject = I18n.t("registration.confirmation_subject", name: organisation.name)
      mail(to: @user.email, subject: @subject)
    end

    def org_notification(organisation, admin)
      @organisation = organisation
      @admin = admin
      @user = organisation.owner
      @subject = I18n.t("registration.notification_subject", name: organisation.name)
      mail(to: @admin.email, subject: @subject)
    end

    def org_welcome(organisation, token)
      @organisation = organisation
      @user = organisation.owner
      @token = token
      @subject = I18n.t("registration.welcome_subject", name: organisation.name)
      mail(to: @user.email, subject: @subject)
    end

  end
end