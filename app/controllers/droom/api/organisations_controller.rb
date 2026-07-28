module Droom::Api
  class OrganisationsController < Droom::Api::ApiController

    load_and_authorize_resource class: "Droom::Organisation"

    def index
      return_organisations
    end

    def show
      return_organisation
    end

    def update
      if @organisation.update(organisation_params)
        return_organisation
      else
        return_errors
      end
    end

    def create
      if @organisation && @organisation.persisted?
        return_organisation
      else
        return_errors
      end
    end

    def destroy
      if @organisation.destroy
        render_api_success
      else 
        render_api_error(errors: @organisation.errors, status: :unprocessable_entity)
      end
    end

    def return_organisations
      render_api_success(resource: @organisations, each_serializer: Droom::OrganisationSerializer)
    end

    def return_organisation
      render_api_success(resource: @organisation, serializer: Droom::OrganisationSerializer)
    end

    def return_errors
      render_api_error(errors: @organisation.errors, status: :unprocessable_entity)
    end

    protected

    def organisation_params
      params.require(:organisation).permit(:name, :description, :keywords, :owner, :owner_id, :chinese_name, :phone, :address, :organisation_type_id, :url, :facebook_page, :twitter_id, :instagram_id, :weibo_id, :image_date, :image_name, :logo_data, :logo_name)
    end

    def registration_params
      params.require(:organisation).permit(:name, :description, :keywords, :chinese_name, :organisation_type_id, :url, owner_attributes: [:given_name, :family_name, :chinese_name, :email])
    end

  end
end