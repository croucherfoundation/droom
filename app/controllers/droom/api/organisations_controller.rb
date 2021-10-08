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
      @organisation.destroy
      head :ok
    end

    def return_organisations
      render json: Droom::OrganisationSerializer.new(@organisations)
    end

    def return_organisation
      render json: Droom::OrganisationSerializer.new(@organisation)
    end

    def return_errors
      render json: { errors: @organisation.errors.to_a }
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
