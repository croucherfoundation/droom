module Droom::Api
  class DocumentsController < Droom::Api::ApiController
    before_action :set_document
    load_resource class: "Droom::Document"

    def show
      render json: @document, serializer: Droom::DocumentSerializer
    end

    private
    def set_document
      @document = Droom::Document.find(params[:id])
    end

  end
end