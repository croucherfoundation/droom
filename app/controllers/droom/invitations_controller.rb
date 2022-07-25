module Droom
  class InvitationsController < Droom::DroomController
    respond_to :js, :html
    
    load_and_authorize_resource :event, :class => Droom::Event
    load_and_authorize_resource :invitation, :through => :event, :class => Droom::Invitation
    
    def destroy
      @invitation.destroy
      head :ok
    end
    
    def index
      @event = Droom::Event.find(params[:event_id])
      render :partial => 'droom/events/invitations'
    end
    
    def new
      respond_with @invitation
    end
    
    def create
      if @invitation.update(invitation_params)
        render :partial => "created"
      else
        respond_with @invitation
      end
    end
    
    def accept
      @invitation.update_attribute(:response, 2)
      if params[:event_invitation]
        @event = @invitation.event
        @event_invitation = Droom::Invitation.where(user_id: current_user.id, event_id: @event.id).first if @event
        render :partial => "droom/events/event_invitation"
      else
        render :partial => "droom/invitations/invitation"
      end
    end

    def refuse
      @invitation.update_attribute(:response, 0)
      if params[:event_invitation]
        @event = @invitation.event
        @event_invitation = Droom::Invitation.where(user_id: current_user.id, event_id: @event.id).first if @event
        render :partial => "droom/events/event_invitation"
      else
        render :partial => "droom/invitations/invitation"
      end
    end

    def toggle
      @invitation.update_attribute(:response, @invitation.response == 0 ? 2 : 0)
      render :partial => "droom/invitations/invitation"
    end

  protected
    
    def invitation_params
      params.require(:invitation).permit(:event_id, :user_id)
    end

  end
end
