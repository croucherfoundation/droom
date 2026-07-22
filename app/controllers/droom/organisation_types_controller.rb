module Droom
  class OrganisationTypesController < Droom::DroomController
    respond_to :html, :js
    load_and_authorize_resource

    def index
      respond_with @organisation_types do |format|
        format.js {
          render :partial => 'droom/organisation_types/organisation_types'
        }
      end
    end

    def new
      respond_with @organisation_type
    end

    def show
      respond_with @organisation_type
    end

    def edit
      respond_with @organisation_type
    end

    def update
      if @organisation_type.update(organisation_type_params)
        set_success_flash_headers(@organisation_type, :update)
        render :partial => 'organisation_type', status: :ok
      else
        render_ajax_error(@organisation_type)
      end
    end

    def create
      if @organisation_type.update(organisation_type_params)
        set_success_flash_headers(@organisation_type, :create)
        render :partial => "created", status: :created
      else
        render_ajax_error(@organisation_type)
      end
    end
    
    def destroy
      @organisation_type.destroy
      set_delete_notice(@organisation_type)
      redirect_to droom.organisation_types_path
    end

  protected
  
    def organisation_type_params
      params.require(:organisation_type).permit(:name, :description, :public, :private)
    end

  end
end
