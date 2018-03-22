module Droom
  class OrganisationsController < Droom::EngineController
    respond_to :html, :js
    layout :no_layout_if_pjax
    helper Droom::DroomHelper

    skip_before_action :authenticate_user!, only: [:signup, :register]
    before_action :search_organisations, only: [:index]
    load_and_authorize_resource except: [:signup, :register]
    before_action :set_view, only: [:show, :edit, :update, :create]

    def show
      unless admin?
        raise ActiveRecord::RecordNotFound unless @organisation.approved?
      end
      render
    end

    def index
      render
    end

    def pending
      @organisations = Droom::Organisation.pending
      render
    end

    def create
      @organisation.update_attributes(organisation_params)
      @organisation.approve!(current_user)
      respond_with @organisation
    end

    def signup
      if Droom.organisations_registerable?
        if @page = Droom::Page.published.find_by(slug: "_signup")
          render template: "droom/pages/published", layout: Droom.page_layout
        else
          @organisation = Droom::Organisation.new
          render
        end
      else
        head :not_allowed
      end
    end

    def register
      if Droom.organisations_registerable?
        @organisation = Droom::Organisation.from_signup registration_params
        @user = @organisation.owner
        @organisation.send_registration_confirmation_messages
        render
      else
        head :not_allowed
      end
    end

    def update
      @organisation.update_attributes(organisation_params)
      respond_with @organisation
    end

    def approve
      @organisation.approve!(current_user)
      redirect_to organisation_url
    end

    def disapprove
      @organisation.disapprove!(current_user)
      redirect_to organisation_url
    end

    def destroy
      @organisation.destroy
      head :ok
    end

  protected

    def organisation_params
      if params[:organisation]
        params.require(:organisation).permit(:name, :description, :keywords, :owner, :owner_id, :chinese_name, :phone, :address, :organisation_type_id, :url, :facebook_page, :twitter_id, :instagram_id, :weibo_id, :image, :logo, :external)
      else
        {}
      end
    end

    def registration_params
      if params[:organisation]
        params.require(:organisation).permit(:name, :description, :keywords, :chinese_name, :organisation_type_id, :url, owner: [:given_name, :family_name, :chinese_name, :email])
      else
        {}
      end
    end

    def set_view
      @view = params[:view] if %w{page listed gridded quick full status}.include?(params[:view])
    end

    def search_organisations
      if params[:q].present?
        @terms = params[:q]
        arguments = { order: {_score: :desc}}
      else
        @terms = '*'
        arguments = { order: {name: :asc}}
      end

      if params[:show] == "all"
        arguments[:limit] = 1000
      else
        @per_page = arguments[:per_page] = (params[:show].presence || 50).to_i
        @page = arguments[:page] = (params[:page].presence || 1).to_i
      end

      criteria = {}

      if params[:external] and params[:external] != 'false'
        @external = criteria[:external] = !!params[:external]
      else
        @external = criteria[:external] = false
      end

      unless admin?
        criteria[:approved] = true
      end

      arguments[:fields] = ['name^10', 'chinese_name', 'description', 'url', 'address', 'people']
      arguments[:where] = criteria

      @organisations = Droom::Organisation.search @terms, arguments
    end

  end
end