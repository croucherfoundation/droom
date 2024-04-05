module Droom
  class GroupInvitationMailer < ActionMailer::Base
    layout Droom.email_layout
    default from: %{'Croucher Foundation' <#{Droom.email_from}>}
    helper ApplicationHelper

    after_action :prevent_delivery_in_nonproduction

    def send_invitation(user, event)
      @user = user
      @event = event
      @subject = "Invitation to #{@event.name}"
      
      if Rails.env.production?
        @email = @user.email
      else
        @email = Settings.email.sandbox
      end
      
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
