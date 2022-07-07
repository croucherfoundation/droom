module Droom
  class GroupInvitationsController < Droom::DroomController
    respond_to :js, :html

    load_and_authorize_resource :event, :class => Droom::Event
    load_and_authorize_resource :group_invitation, :through => :event, :class => Droom::GroupInvitation

    def destroy
      @group_invitation.destroy
      head :ok
    end

    def index
      @event = Droom::Event.find(params[:event_id])
      render :partial => 'attending_groups'
    end

    def new
      respond_with @group_invitation
    end

    def create
      Droom::GroupInvitationJob.perform_now(group_invitation_params[:group_id], params[:event_id])

      if GroupInvitation.find_by(group_id: group_invitation_params[:group_id], event_id: params[:event_id])
        Rails.logger.warn "⚠️ Email sent to already invited group!."
        return true
      end
      
      if @group_invitation.update(group_invitation_params)
        render :partial => "created"
      else
        respond_with @group_invitation
      end
    end

  protected

    def group_invitation_params
      params.require(:group_invitation).permit(:event_id, :group_id)
    end

  end
end
