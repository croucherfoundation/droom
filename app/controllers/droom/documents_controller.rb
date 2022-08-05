module Droom
  class DocumentsController < Droom::DroomController
    respond_to :html, :js, :json

    before_action :get_folder, except: [:index, :suggest, :reposition]
    before_action :select_documents, only: [:index, :suggest]
    load_and_authorize_resource :document, :class => Droom::Document, :through => :folder, :shallow => true, except: [:index, :suggest]
    before_action :find_by_name, only: [:create]


    def index
      respond_with @documents do |format|
        format.js { render :partial => 'droom/documents/documents' }
      end
    end

    def suggest
      respond_with @documents, layout: false
    end

    def show
      if @document.file
        redirect_to @document.file.expiring_url(600)
      else
        raise ActiveRecord::RecordNotFound
      end
    end

    def new
      render
    end

    def create
      if @data.exists?
        render json: 'File with this name already exists!', status: 409
      else
        @document.save!
        if %w{listing simple}.include?(params[:view])
          render :partial => params[:view]
        else
          render :partial => 'listing'
        end
      end
    end

    def edit
      render
    end

    def update
      attributes = document_params
      attributes[:name] = params[:filename] + params[:extension]
      @data = Document.where(name: attributes[:name], folder_id: params[:folder_id])

      @document.assign_attributes(attributes)

      if @document.description_changed? || @data.blank?
        if @document.name_changed?
          @document.synchronize_with_s3
          @document.save
        end
        render json: @document.to_json
      else
        render json: 'File with this name already exists!', status: 409
      end
    end

    def reposition
      @document.update(reposition_params)
      head :ok
    end

    def destroy
      @document.destroy
      # @document.enqueue_for_croucher_deindexing # calling search_client method
      head :ok
    end

  protected

    def find_by_name
      @data = Document.where(name: document_params[:name], folder_id: params[:folder_id])
    end

    def select_documents
      if params[:q].present?
        @q = params[:q]
        terms = params[:q]
        order = {_score: :desc}
      else
        terms = "*"
        order = {name: :asc}
      end

      criteria = {}
      criteria[:event_type] = params[:event_type] if params[:event_type].present?
      criteria[:year] = params[:year] if params[:year].present?
      criteria[:content_type] = params[:content_type] if params[:content_type].present?

      unless current_user.privileged?
        criteria[:confidential] = false
      end

      fields = ["name^10", "filename^5", "content"]
      highlight = {tag: "<strong>", fields: {content: {fragment_size: 320}}}
      aggregations = {
        year: {},
        event_type: {},
        content_type: {}
      }

      @show = (params[:show].presence || 20).to_i
      @page = (params[:page].presence || 1).to_i
      @searching = @q.present? || criteria.any?
      # even if not yet searching, we perform the query to make aggregation facets available.
      # ui can check for @searching if the default list is not a useful browser.
      @documents = Document.search terms, fields: fields, where: criteria, order: order, per_page: @show, page: @page, highlight: highlight, aggs: aggregations
    end

    def document_params
      if params[:document]
        params.require(:document).permit(:name, :file, :description, :folder_id, :position)
      else
        {}
      end
    end

    def reposition_params
      if params[:document]
        params.require(:document).permit(:position, :folder_id)
      else
        {}
      end
    end

    def get_folder
      @folder = Droom::Folder.find(params[:folder_id])
    end

  end
end
