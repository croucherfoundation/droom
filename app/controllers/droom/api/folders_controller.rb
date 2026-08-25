module Droom::Api
  class FoldersController < Droom::Api::ApiController
    before_action :set_folder
    load_resource class: "Droom::Folder"

    def show
      render_api_success(resource: @folder, serializer: Droom::FolderSerializer)
    end

    def children
      @subfolders = @folder.children
      render_api_success(resource: @subfolders, each_serializer: Droom::FolderSerializer)
    end

    def documents
      render_api_success(resource: @folder.documents, each_serializer: Droom::DocumentSerializer)
    end

    def all_documents
      @documents = @folder.descendants.map(&:documents).flatten
      render_api_success(resource: @documents, each_serializer: Droom::DocumentSerializer)
    end

    private

      def set_folder
        @folder = Droom::Folder.find(params[:id])
      end

  end
end