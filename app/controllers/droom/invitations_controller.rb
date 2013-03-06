module Droom
  class InvitationsController < Droom::EngineController
    respond_to :js, :html
    layout :no_layout_if_pjax
    
    before_filter :build_invitation, :only => [:new, :create]
    before_filter :get_invitation, :only => [:destroy, :accept, :reject]

    def destroy
      @invitation.destroy
      head :ok
    end
    
    def index
      @event = Droom::Event.find(params[:event_id])
      render :partial => 'attending_people'
    end
    
    def new
      respond_with @invitation
    end
    
    def create
      if @invitation.save
        render :partial => "created"
      else
        respond_with @invitation
      end
    end
    
    def accept
      @invitation.update_attribute(:response, 2)
      render :partial => "droom/invitations/invitation"
    end

    def reject
      @invitation.update_attribute(:response, 0)
      render :partial => "droom/invitations/invitation"
    end

  protected
    
    def build_invitation
      @event = Droom::Event.find(params[:event_id])
      @invitation = @event.invitations.new(params[:invitation])
    end

    def get_invitation
      @invitation = Droom::Invitation.find(params[:id])
    end

  end
end
