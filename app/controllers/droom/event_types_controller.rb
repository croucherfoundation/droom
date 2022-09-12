module Droom
  class EventTypesController < Droom::DroomController
    respond_to :html, :js
    load_and_authorize_resource

    def index
      respond_with @event_types do |format|
        format.js {
          render :partial => 'droom/event_types/event_types'
        }
      end
    end

    def new
      respond_with @event_type
    end

    def show
      @timezone_feature = FeatureFlag.enabled?('time-zone-feature', current_user)
      respond_with @event_type
    end

    def edit
      respond_with @event_type
    end

    def update
      @event_type.update(event_type_params)
      render :partial => 'event_type'
    end

    def create
      if @event_type.update(event_type_params)
        render :partial => "created"
      else
        respond_with @event_type
      end
    end
    
    def destroy
      @event_type.destroy
      head :ok
    end

  protected
  
    def event_type_params
      params.require(:event_type).permit(:name, :description, :public, :private)
    end

  end
end
