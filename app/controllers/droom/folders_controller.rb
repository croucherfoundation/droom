module Droom
  class FoldersController < Droom::DroomController
    respond_to :html, :json, :js
    layout :no_layout_if_pjax, only: [:index, :show]

    LIBRARY_VIEWS = %w[my_library shared data_room favourites].freeze

    before_action :set_library_view, only: [:new, :create, :edit, :update]
    before_action :get_root_folders, :only => [:index]
    before_action :get_home_documents, :only => [:index]
    before_action :get_parent_folder, :only => [:new, :create]
    before_action :find_by_name, only: [:create, :update]
    before_action :get_links, :only => [:index]
    before_action :load_accessible_folder, only: [:show]
    load_and_authorize_resource find_by: :uid, class: "Droom::Folder"
    skip_load_and_authorize_resource only: [:show, :child_folders]

    def index
      set_library_view
      @sortable = params[:sortable] == 'true'
      @q = params[:q].to_s.strip
      @filtering = filter_params_present?
      @searching = @q.present? || @filtering

      @folders = apply_library_view_scope(@folders)
      @home_documents = apply_library_view_scope(@home_documents)

      # For favourites view, load all favourited documents (not just home folder)
      # Exclude docs already inside a favourited folder to avoid duplicates
      if @library_view == 'favourites'
        fav_folder_ids = @folders.pluck(:id)
        docs = Droom::Document.favourited_by(current_user)
        docs = docs.where.not(folder_id: fav_folder_ids) if fav_folder_ids.any?
        @favourited_documents = docs
      end

      prepare_library_search unless @sortable && !@searching
      return if performed?

      unless @searching
        @folders = @folders.populated unless current_user.admin? || @library_view == 'data_room'
      end

      return if render_library_fragment('droom/folders/folders')

      respond_with @folders do |format|
        format.html
        format.js { render partial: 'droom/folders/folders' }
      end
    end

    def show
      set_library_view
      @sortable = params[:sortable] == 'true'
      @skip_gdoc = params[:skip_gdoc] == 'true'
      @q = params[:q].to_s.strip
      @filtering = filter_params_present?
      @searching = @q.present? || @filtering

      prepare_library_search(folder: @folder) unless @sortable && !@searching
      return if performed?

      return if render_library_fragment('droom/folders/show/contents')

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
      @folder.uid ||= SecureRandom.uuid
      respond_with @folder
    end

    def create
      if params[:creation_token].present?
        unless params[:creation_token].to_s.match?(/\A[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\z/i)
          render json: 'Invalid folder creation token. Reopen the folder form and try again.', status: :unprocessable_entity
          return
        end
        @folder.uid = params[:creation_token]
      end
      if @data.exists?
        render json: 'Folder with this name already exists!', status: 409
      else
        @folder.assign_attributes(folder_params.except(:data_room, :parent_id).merge(created_by: current_user))
        if @library_view == 'data_room' && @parent && !@parent.data_room?
          render json: 'This parent is not shared with the data room. Choose a shared parent or create in myLibrary.', status: :unprocessable_entity
          return
        end
        @folder.data_room = @folder.parent ? @folder.parent.data_room? : @library_view == 'data_room'
        @folder.inherit_confidentiality if @parent
        if @folder.save
          respond_with @folder do |format|
            format.html { render :partial => 'droom/folders/folder' }
            format.js { render :partial => "droom/folders/folder" }
          end
        else
          render json: @folder.errors.full_messages.to_sentence, status: :unprocessable_entity
        end
      end
    rescue ActiveRecord::RecordNotUnique
      render json: 'This folder may already have been saved. Refresh the destination before trying again.', status: :conflict
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
      @folder.insert_at(params[:position].to_i)
      head :ok
    end

    def move_folder
      respond_with @folder
    end

    def moved
      if parent_folder = Droom::Folder.find_by(uid: params[:new_parent_id])
        @folder.parent_id = parent_folder.id
        @folder.save
      end
      head :ok
    end

    def child_folders
      if params.include?('target_parent_id')
        target_parent_id = params[:target_parent_id]
        mapped_children = ''
        if target_parent_id != '' && folder = Droom::Folder.accessible_to(current_user).find_by(uid: target_parent_id)
          child_folders = folder.children.merge(Droom::Folder.accessible_to(current_user)).not_hidden
          child_folders = child_folders.other_than(Droom::Folder.home_documents_folder)
          if params[:exclude_id].present? && excluded = Droom::Folder.find_by(uid: params[:exclude_id])
            child_folders = child_folders.other_than(excluded)
          end
          if child_folders.any?
            mapped_children = {}
            child_folders.map{|child|
              mapped_children[child.uid] = child.name
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
      params.require(:folder).permit(:name, :slug, :parent_id, :data_room)
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

    def get_parent_folder
      if params[:folder_id].present?
        @parent = Droom::Folder.find_by!(uid: params[:folder_id])
        if params[:folder].present? && folder_params[:parent_id].present? && folder_params[:parent_id].to_s != @parent.id.to_s
          raise ActionController::BadRequest, 'Folder parent does not match the selected destination'
        end
      elsif params[:folder].present? && folder_params[:parent_id].present?
        @parent = Droom::Folder.find(folder_params[:parent_id])
      end
      if @parent
        authorize! :read, @parent
        authorize! :update, @parent
      end
      if @parent && !@parent.data_room? && params[:view].blank? && @library_view == 'data_room'
        @library_view = 'my_library'
      end
      @folder = @parent ? @parent.children.build : Droom::Folder.new
    end

    def load_accessible_folder
      @folder = Droom::Folder.accessible_to(current_user).find_by!(uid: params[:id])
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

    def render_library_fragment(partial)
      response.headers['Vary'] = (response.headers['Vary'].to_s.split(/,\s*/) | ['X-Library-Fragment']).join(', ')
      return false unless request.headers['X-Library-Fragment'] == '1'
      no_store
      render partial: partial
      true
    end

    def prepare_library_search(folder: nil)
      visible_folders = Folder.accessible_to(current_user)
      visible_folders = visible_folders.where(private: [nil, false]) unless current_user.privileged?
      visible_documents = Document.accessible_to(current_user)
      documents = visible_documents.where(folder_id: visible_folders.except(:includes, :order).select(:id))
                                   .or(visible_documents.where(folder_id: nil))
      documents = documents.where(private: [nil, false]) unless current_user.privileged?
      folders = apply_library_view_scope(visible_folders)
      documents = apply_library_view_scope(documents)
      if folder
        folders = folders.where(id: folder.descendant_ids)
        documents = documents.where(folder_id: folder.subtree_ids)
      end
      search = LibrarySearch.new(user: current_user, folders: folders, documents: documents, params: params)
      if request.format.json? && params.key?(:people_query)
        no_store
        term = params[:people_query].to_s.strip
        users = term.size.between?(2, 128) && can?(:search, User) ? search.matching_uploaders(term) : []
        render json: users.map { |user| {id: user.id, name: user.formal_name} }
        return
      end

      @show = search.page_size
      @search_results = search.results(browsing: !@searching)
      @library_filter_fields = search.filter_fields(@search_results)
      if params[:user_id].present? && can?(:search, User) && (@search_results.total_count.positive? || search.uploader_visible?(params[:user_id]))
        @filter_user = User.undeleted.find_by(id: params[:user_id])
      end
    rescue StandardError => error
      # The pinned transport can wrap a Faraday error while handling it.
      recoverable = [Faraday::ConnectionFailed, Faraday::TimeoutError, Searchkick::MissingIndexError,
                     Elasticsearch::Transport::Transport::Errors::ServiceUnavailable]
      raise if @searching || request.format.json? || recoverable.none? { |type| error.is_a?(type) || error.cause.is_a?(type) }
      # Browsing and sorting use SQL, so a search outage must not hide those records.
      Rails.logger.warn("Library browse filter counts unavailable (#{error.class})")
      @library_filter_fields = LibrarySearch::FILTERS.map { |field, label, choices| [field, label, choices.map { |value, text| [text, value] }] }
    end

    def filter_params_present?
      params[:type].present? || params[:modified].present? || params[:user_id].present?
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
