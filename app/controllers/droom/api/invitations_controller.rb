module Droom::Api
  class InvitationsController < Droom::Api::ApiController
    before_action :find_event

    def create
      user = Droom::User.find(params[:invitation][:user_id])
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
      @event = Droom::Event.find(params[:event_id])
    end
  end
end
