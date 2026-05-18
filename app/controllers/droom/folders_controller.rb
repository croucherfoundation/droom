module Droom
  class FoldersController < Droom::DroomController
    respond_to :html, :json, :js
    layout :no_layout_if_pjax, only: [:index, :show]

    LIBRARY_VIEWS = %w[my_library shared data_room favourites].freeze

    before_action :get_root_folders, :only => [:index]
    before_action :get_home_documents, :only => [:index]
    before_action :get_parent_folder, :only => [:new, :create]
    before_action :find_by_name, only: [:create, :update]
    before_action :get_links, :only => [:index]
    load_and_authorize_resource

    def index
      set_library_view
      @sortable = params[:sortable] == 'true'
      @q = params[:q].to_s.strip
      @filtering = filter_params_present?
      @searching = @q.present? || @filtering

      @folders = apply_library_view_scope(@folders)
      @home_documents = apply_library_view_scope(@home_documents)

      if @searching
        search_library
      else
        @folders = @folders.populated unless current_user.admin?
      end

      set_filter_ivars

      respond_with @folders do |format|
        format.html
        format.js { render partial: 'droom/folders/folders' }
      end
    end

    def show
      @sortable = params[:sortable] == 'true'
      @skip_gdoc = params[:skip_gdoc] == 'true'
      @q = params[:q].to_s.strip
      @filtering = filter_params_present?
      @searching = @q.present? || @filtering

      search_library(folder: @folder) if @searching

      set_filter_ivars

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
        @folder.update(folder_params.merge(created_by: current_user, data_room: @parent&.data_room?))
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

    def set_library_view
      @library_view = params[:view].presence || session[:library_view]
      @library_view = 'data_room' unless LIBRARY_VIEWS.include?(@library_view)
      session[:library_view] = @library_view
    end

    # Applies the active library view scope to an AR relation (browsing path).
    def apply_library_view_scope(relation)
      case @library_view
      when 'my_library'
        relation.owned_by(current_user)
      when 'shared'
        relation.shared_with(current_user)
      when 'data_room'
        relation.data_room
      when 'favourites'
        relation.favourited_by(current_user)
      else
        relation
      end
    end

    # Applies the active library view as ES/Searchkick criteria (search path).
    # For shared/favourites, pre-fetches IDs since ES can't do joins.
    def apply_library_view_to_criteria(criteria)
      case @library_view
      when 'my_library'
        criteria[:created_by_id] = current_user.id
      when 'shared'
        # Merge new shares (droom_shares) with legacy shares (personal_folders)
        shared_doc_ids = Droom::Share.for_user(current_user).of_type('Droom::Document').pluck(:shareable_id)
        shared_folder_ids = Droom::Share.for_user(current_user).of_type('Droom::Folder').pluck(:shareable_id)
        personal_folder_ids = current_user.personal_folders.pluck(:folder_id)
        personal_doc_ids = Droom::Document.where(folder_id: personal_folder_ids).pluck(:id)
        criteria[:id] = (shared_doc_ids + shared_folder_ids + personal_folder_ids + personal_doc_ids).uniq
        criteria[:created_by_id] = {not: current_user.id}
        criteria[:data_room] = false
      when 'data_room'
        criteria[:data_room] = true
      when 'favourites'
        fav_doc_ids = Droom::Favourite.for_user(current_user).of_type('Droom::Document').pluck(:favouritable_id)
        fav_folder_ids = Droom::Favourite.for_user(current_user).of_type('Droom::Folder').pluck(:favouritable_id)
        criteria[:id] = fav_doc_ids + fav_folder_ids
      end
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
      apply_library_view_to_criteria(criteria)
      criteria[:file_content_type] = Droom::Document::CONTENT_TYPE_GROUPS[params[:type]] if params[:type].present? && params[:type] != 'folders'
      criteria[:modified_at] = {gte: modified_since_time} if params[:modified].present? && modified_since_time
      criteria[:created_by_id] = params[:user_id].to_i if params[:user_id].present?
      @show = (params[:show].presence || 20).to_i
      @page = (params[:page].presence || 1).to_i
      query = @q.present? ? @q : "*"
      @search_results = Searchkick.search query,
        models: search_models,
        fields: fields,
        where: criteria,
        order: {_score: :desc},
        per_page: @show,
        page: @page
    end

    def set_filter_ivars
      @filter_type = params[:type].presence
      @filter_modified = params[:modified].presence
      @filter_user_id = params[:user_id].presence
      @filter_user = Droom::User.find_by(id: @filter_user_id) if @filter_user_id.present?
    end

    def filter_params_present?
      params[:type].present? || params[:modified].present? || params[:user_id].present?
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
