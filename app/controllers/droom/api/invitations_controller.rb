module Droom::Api
  class InvitationsController < Droom::Api::ApiController
    load_resource :event, class: Droom::Event, find_by: :uuid

    def index
      @invitations = @event.invitations
      render_api_success(resource: @invitations)
    end

    def create
      user_identifier = params[:invitation][:user_id]
      user = Droom::User.find_by(uid: user_identifier) || Droom::User.find(user_identifier)
      @invitation = @event.invitations.find_or_initialize_by(user_id: user.id)
      if @invitation.new_record?
        @invitation.save!
        render_api_success(resource: @invitation, status: :created)
      else
        render_api_success(resource: @invitation, status: :ok)
      end
    end

    def destroy
      @invitation = @event.invitations.find(params[:id])
      if @invitation.destroy
        render_api_success
      else
        render_api_error(errors: @invitation.errors, status: :unprocessable_entity)
      end
    end
  end
end
