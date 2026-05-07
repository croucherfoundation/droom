module Droom
  class FoldersController < Droom::DroomController
    respond_to :html, :json, :js
    layout :no_layout_if_pjax, only: [:index, :show]

    before_action :get_root_folders, :only => [:index]
    before_action :get_home_documents, :only => [:index]
    before_action :get_parent_folder, :only => [:new, :create]
    before_action :find_by_name, only: [:create, :update]
    before_action :get_links, :only => [:index]
    load_and_authorize_resource

    def index
      @sortable = params[:sortable] == 'true'
      @q = params[:q].to_s.strip
      @searching = @q.present?

      if @searching
        search_library
      else
        @folders = @folders.populated unless current_user.admin?
      end

      apply_filters

      respond_with @folders do |format|
        format.html
        format.js { render partial: 'droom/folders/folders' }
      end
    end

    def show
      @sortable = params[:sortable] == 'true'
      @skip_gdoc = params[:skip_gdoc] == 'true'
      @q = params[:q].to_s.strip
      @searching = @q.present?

      search_library(folder: @folder) if @searching

      apply_filters

      respond_with @folder do |format|
        format.html
        format.js {
          if params[:source] == 'library'
            render :partial => 'droom/folders/show/contents'
          else
            render :partial => 'droom/folders/folder'
          end
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
        @folder.update(folder_params.merge(created_by: current_user))
        respond_with @folder do |format|
          format.html { render :partial => 'droom/folders/folder' }
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
          format.html { render :partial => 'droom/folders/folder' }
          format.js { render :partial => "droom/folders/folder" }
        end
      end
    end

    def destroy
      @folder.destroy
      head :ok
    end

    def reposition
      folder = Droom::Folder.find(params[:id])
      folder.insert_at(params[:position].to_i)
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
      if folder_params[:parent_id].present?
        parent = Folder.find_by(id: folder_params[:parent_id])

        @data = if parent
          parent.children.where(name: folder_params[:name])
        else
          Folder.none
        end
      else
        # Top-level folders (ancestry == nil)
        @data = Folder.where(name: folder_params[:name], ancestry: nil)
      end
    end

    def get_links
      @links = Droom::Link.all
    end

    def folder_params
      params.require(:folder).permit(:name, :slug, :parent_id)
    end

    def get_root_folders
      @folders = Droom::Folder.roots.not_hidden
    end

    def get_home_documents
      @home_folder = Droom::Folder.home_documents_folder
      @home_documents = @home_folder.documents
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

    def search_library(folder: nil)
      fields = ["name^10", "filename^5"]
      criteria = {}
      criteria[:confidential] = false unless current_user.privileged?
      if folder
        descendant_ids = folder.subtree_ids
        criteria[:folder_id] = descendant_ids
        criteria[:id] = {not: folder.id}
      end
      criteria[:content_type] = Droom::Document::CONTENT_TYPE_GROUPS[params[:type]] if params[:type].present? && params[:type] != 'folders'
      criteria[:modified_at] = {gte: modified_since_time} if params[:modified].present? && modified_since_time
      @show = (params[:show].presence || 20).to_i
      @page = (params[:page].presence || 1).to_i
      @search_results = Searchkick.search @q,
        models: search_models,
        fields: fields,
        where: criteria,
        order: {_score: :desc},
        per_page: @show,
        page: @page
    end

    def apply_filters
      @filter_type = params[:type].presence
      @filter_modified = params[:modified].presence
      @filtering = @filter_type.present? || @filter_modified.present?

      return unless @filtering && !@searching

      if @filter_type.present?
        @folders = @folders.by_type(@filter_type) if @folders
        @home_documents = @home_documents.by_type(@filter_type) if @home_documents
        @filtered_documents = -> (docs) { docs.by_type(@filter_type) }
      end

      if @filter_modified.present?
        @home_documents = @home_documents.modified_since(@filter_modified) if @home_documents
        @filtered_documents_modified = -> (docs) { docs.modified_since(@filter_modified) }
        # Folders don't have a modified filter — they remain visible
      end
    end

    def search_models
      if params[:type] == 'folders'
        [Droom::Folder]
      elsif params[:type].present?
        [Droom::Document]
      else
        [Droom::Folder, Droom::Document]
      end
    end

    def modified_since_time
      case params[:modified]
      when '7d'   then 7.days.ago
      when '30d'  then 30.days.ago
      when '365d' then 365.days.ago
      end
    end

    def default_layout
      if %w[index show].include?(action_name)
        'centered'
      else
        Droom.config.layout
      end
    end
  end
end
