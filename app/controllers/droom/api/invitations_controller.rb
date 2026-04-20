module Droom::Api
  class InvitationsController < Droom::Api::ApiController
    before_action :find_event

    def index
      @invitations = @event.invitations
      render json: {
        invitations: @invitations.map do |invitation|
          {
            id: invitation.id,
            event_id: @event.uuid,
            user_id: invitation.user_id,
            user_uid: invitation.user&.uid
          }
        end
      }
    end

    def create
      user_identifier = params[:invitation][:user_id]
      user = Droom::User.find_by(uid: user_identifier) || Droom::User.find(user_identifier)
      @invitation = @event.invitations.find_or_initialize_by(user_id: user.id)
      if @invitation.new_record?
        @invitation.save!
        render json: { invitation: { id: @invitation.id, event_id: @event.id, user_id: user.id } }, status: :created
      else
        render json: { invitation: { id: @invitation.id, event_id: @event.id, user_id: user.id } }, status: :ok
      end
    end

    def destroy
      @invitation = @event.invitations.find(params[:id])
      @invitation.destroy
      head :ok
    end

  protected

    def find_event
      @event = Droom::Event.find_by!(uuid: params[:event_id])
    end
  end
end
