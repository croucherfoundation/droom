module Droom::Api
  class DocumentsController < Droom::Api::ApiController
    before_action :get_documents, only: [:index]
    load_resource class: "Droom::Document"

    def index
      render json: @documents, each_serializer: Droom::DocumentSerializer
    end

    def show
      render json: @document, serializer: Droom::DocumentSerializer
    end

    private

      def get_documents
        if params[:folder_id].present?
          @folder = Droom::Folder.find(params[:folder_id])
          @documents = @folder.descendants.map(&:documents).flatten
        end
      end

  end
end