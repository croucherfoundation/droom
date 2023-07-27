module Droom::Api
  class FoldersController < Droom::Api::ApiController
    before_action :set_folder
    load_resource class: "Droom::Folder"

    def show
      render json: @folder, serializer: Droom::FolderSerializer
    end

    def children
      @subfolders = @folder.children
      render json: @subfolders, each_serializer: Droom::FolderSerializer
    end

    def documents
      render json: @folder.documents, each_serializer: Droom::DocumentSerializer
    end

    def all_documents
      @documents = @folder.descendants.map(&:documents).flatten
      render json: @documents, each_serializer: Droom::DocumentSerializer
    end

    private

      def set_folder
        @folder = Droom::Folder.find(params[:id])
      end

  end
end