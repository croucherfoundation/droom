module Droom::Api
  class InvitationsController < Droom::Api::ApiController
    load_resource :event, class: Droom::Event, find_by: :uuid

    def index
      @invitations = @event.invitations
      render json: @invitations
    end

    def create
      user_identifier = params[:invitation][:user_id]
      user = Droom::User.find_by(uid: user_identifier) || Droom::User.find(user_identifier)
      @invitation = @event.invitations.find_or_initialize_by(user_id: user.id)
      if @invitation.new_record?
        @invitation.save!
        render json: @invitation, status: :created
      else
        render json: @invitation, status: :ok
      end
    end

    def destroy
      @invitation = @event.invitations.find(params[:id])
      @invitation.destroy
      head :ok
    end
  end
end
