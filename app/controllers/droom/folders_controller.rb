module Droom
  class FoldersController < Droom::DroomController
    respond_to :html, :json, :js

    before_action :get_root_folders, :only => [:index]
    before_action :get_parent_folder, :only => [:new, :create]
    before_action :find_by_name, only: [:create, :update]
    load_and_authorize_resource

    def index
      @folders = @folders.populated unless current_user.admin?
      respond_with @folders do |format|
        format.js {
          render :partial => 'droom/folders/folders'
        }
      end
    end

    def show
      respond_with @folder do |format|
        format.js {
          render :partial => 'droom/folders/folder'
        }
      end
    end

    def new
      respond_with @folder
    end

    def create
      if @data.exists?
        render json: 'Folder with this name already exists!', status: 409
      else
        @folder.update(folder_params)
        respond_with @folder do |format|
          format.js { render :partial => "droom/folders/folder" }
        end
      end
    end

    def edit
      respond_with @folder
    end

    def update
      @folder.assign_attributes(folder_params)
      if @folder.name_changed? && @data.exists?
        render json: 'Folder with this name already exists!', status: 409
      else
        @folder.save
        respond_with @folder do |format|
          format.js { render :partial => "droom/folders/folder" }
        end
      end
    end

    def destroy
      @folder.destroy
      head :ok
    end

    def move_folder
      respond_with @folder
    end

    def moved
      if params.include?('new_parent_id') && params.include?('id')
        folder = Droom::Folder.find(params[:id])
        folder.parent_id = params[:new_parent_id]
        folder.save
      end
      head :ok
    end

    def child_folders
      if params.include?('target_parent_id')
        target_parent_id = params[:target_parent_id]
        mapped_children = ''
        if target_parent_id != '' && folder = Droom::Folder.find(target_parent_id)
          child_folders = folder.children
          if child_folders.any?
            mapped_children = {}
            child_folders.map{|child|
              mapped_children[child.id] = child.name
            }
          end
        end
      end
      render json: mapped_children
    end

  protected

    def find_by_name
      @data = Folder.where(name: folder_params[:name])
      @data = @data.where(parent_id: folder_params[:parent_id]) if folder_params[:parent_id].present?
    end

    def folder_params
      params.require(:folder).permit(:name, :slug, :parent_id)
    end

    def get_root_folders
      @folders = Droom::Folder.roots
    end

    def get_parent_folder
      if @parent = Droom::Folder.find_by(id: params[:folder_id])
        @folder = @parent.children.build
      else
        @folder = Droom::Folder.new
      end
    end

    def get_folder_tree
      @child_map = Droom::Folder.non_roots.each_with_object({}) do |f, children|
        children[f.parent_id] ||= []
        children[f.parent_id].push(f)
      end
      @document_map = Droom::Document.all.each_with_object({}) do |d, contents|
        contents[d.folder_id] ||= []
        contents[d.folder_id].push(d)
      end
    end
  end
end
