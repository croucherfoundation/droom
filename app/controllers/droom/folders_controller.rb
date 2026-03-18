module Droom
  class FoldersController < Droom::DroomController
    respond_to :html, :json, :js
    layout :no_layout_if_pjax, only: [:index]

    before_action :get_root_folders, :only => [:index]
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

      respond_with @folders
    end

    def show
      @sortable = params[:sortable] == 'true'
      @skip_gdoc = params[:skip_gdoc] == 'true'
      respond_with @folder do |format|
        format.html { render layout: 'centered' }
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
          format.html { render :partial => 'droom/folders/show/contents' }
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
          format.html { render :partial => 'droom/folders/show/contents' }
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

    def search_library
      fields = ["name^10", "filename^5", "content"]
      highlight = {tag: "<strong>", fields: {name: {}, content: {fragment_size: 320}}}
      criteria = {}
      criteria[:confidential] = false unless current_user.privileged?
      @show = (params[:show].presence || 20).to_i
      @page = (params[:page].presence || 1).to_i
      @search_results = Searchkick.search @q,
        models: [Droom::Folder, Droom::Document],
        fields: fields,
        where: criteria,
        order: {_score: :desc},
        per_page: @show,
        page: @page,
        highlight: highlight
    end

    def default_layout
      if %w[index].include?(action_name)
        'centered'
      else
        Droom.config.layout
      end
    end
  end
end
