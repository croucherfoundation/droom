module Droom
  class GroupInvitationMailer < ActionMailer::Base
    layout Droom.email_layout
    default from: %{#{Droom.email_from_name} <#{Droom.email_from}>}
    helper ApplicationHelper

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
  end
end
