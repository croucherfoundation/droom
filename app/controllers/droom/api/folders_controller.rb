module Droom::Api
  class FoldersController < Droom::Api::ApiController
    before_action :set_folder
    load_resource class: "Droom::Folder"

    def show
      render_api_success(resource: @folder, serializer: Droom::FolderSerializer)
    end

    def children
      @subfolders = @folder.children.merge(Droom::Folder.accessible_to(current_user))
      render_api_success(resource: @subfolders, each_serializer: Droom::FolderSerializer)
    end

    def documents
      documents = @folder.documents.merge(Droom::Document.accessible_to(current_user))
      render_api_success(resource: documents, each_serializer: Droom::DocumentSerializer)
    end

    def all_documents
      accessible_folder_ids = Droom::Folder.accessible_to(current_user)
        .where(id: @folder.subtree_ids - [@folder.id])
        .pluck(:id)
      @documents = Droom::Document.accessible_to(current_user).where(folder_id: accessible_folder_ids)
      render_api_success(resource: @documents, each_serializer: Droom::DocumentSerializer)
    end

    private

      def set_folder
        @folder = Droom::Folder.accessible_to(current_user).find(params[:id])
      end

  end
end
