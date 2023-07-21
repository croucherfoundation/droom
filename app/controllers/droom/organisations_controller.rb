module Droom
  class OrganisationsController < Droom::DroomController
    include Droom::Concerns::Searchable
    helper Droom::DroomHelper
    respond_to :html, :js

    load_and_authorize_resource
    before_action :set_view, only: [:show, :edit, :update, :create]

    def show
      raise ActiveRecord::RecordNotFound unless admin? || @organisation.approved?
      render
    end

    def index
      @external = params[:external] unless params[:external] == 'false'
      render
    end

    def pending
      @organisations = Droom::Organisation.pending
      render
    end

    def create
      @organisation.owner_id = current_user.id if @organisation.owner_id.nil?
      @organisation.update(organisation_params) 
      @organisation.approve!(current_user)
      respond_with @organisation
    end

    def update
      @organisation.update(organisation_params)
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

    # always an ajax call so for now we only confirm.
    def merge
      @other_org = Droom::Organisation.find(merge_params[:other_id])
      @other_org.subsume(@organisation)
      head :no_content
    end

    def destroy
      @organisation.destroy
      head :ok
    end

  protected

    def organisation_params
      if params[:organisation]
        params.require(:organisation).permit(:name, :description, :keywords, :owner, :owner_id, :chinese_name, :phone, :address, :organisation_type_id, :url, :facebook_page, :twitter_id, :instagram_id, :weibo_id, :image, :logo, :external, :joinable, :email_domain, tag_ids: [], administrator_ids: [])
      else
        {}
      end
    end

    def merge_params
      params.require(:organisation).permit(:other_id)
    end

    def set_view
      @view = params[:view] if %w{page listed gridded quick full status users pending subsume}.include?(params[:view])
    end

    ## Searchable configuration
    #
    def search_fields
      ['name^10', 'chinese_name', 'description', 'url', 'address', 'people']
    end

    def search_highlights
      {tag: "<strong>"}
    end

    def search_default_sort
      "name"
    end

    def search_criterion_params
      [:external]
    end

    def non_admin_filter
      { approved: true }
    end

  end
end