module Droom
  class Folder < Droom::DroomRecord
    has_ancestry
    # don't use Slugged: we need to apply a dynamic parent scope.

    # acts_as_list for ordering folders within the same level (same ancestry)
    # Using column: 'ancestry' to handle the string ancestry column (not a foreign key)
    acts_as_list column: 'position', scope: [:ancestry]

    belongs_to :created_by, :class_name => "Droom::User"
    belongs_to :holder, :polymorphic => true
    has_many :documents, -> {order(position: :asc, file_file_name: :asc)}, :dependent => :destroy
    has_many :personal_folders, :dependent => :destroy
    has_many :favourites, :as => :favouritable, :dependent => :destroy
    has_many :shares, :as => :shareable, :dependent => :destroy

    before_validation :set_properties
    after_save :set_file_path
    validates :slug, presence: true, uniqueness: { scope: :ancestry }

    default_scope -> { includes(:documents).order(:position) }

    scope :non_roots, -> { where.not(ancestry: nil) }
    scope :not_hidden, -> { where(hidden: false) }

    scope :by_type, -> type {
      type == 'folders' ? all : none
    }
    scope :created_by, -> user_id {
      where(created_by_id: user_id)
    }
    # Library view scopes
    scope :owned_by, -> user {
      where(created_by_id: user.id)
    }
    # Merges new sharing (droom_shares) with legacy sharing (personal_folders).
    # Includes folders shared directly OR via an ancestor folder being shared.
    # Excludes own items and data_room items.
    scope :shared_with, -> user {
      directly_shared_ids = Droom::Share.for_user(user).of_type('Droom::Folder').pluck(:shareable_id)
      personal_folder_ids = user.personal_folders.pluck(:folder_id)
      # Expand shared folders to include all their descendants
      ancestor_folder_ids = Droom::Folder.where(id: directly_shared_ids).flat_map { |f| f.subtree_ids }
      all_ids = (ancestor_folder_ids + personal_folder_ids).uniq
      where(id: all_ids)
        .where.not(created_by_id: user.id)
        .where("#{table_name}.data_room != 1 OR #{table_name}.data_room IS NULL")
    }
    scope :data_room, -> { where("#{table_name}.data_room = 1") }
    scope :favourited_by, -> user {
      joins('INNER JOIN droom_favourites AS df ON droom_folders.id = df.favouritable_id AND df.favouritable_type = "Droom::Folder"')
        .where(["df.user_id = ?", user.id])
    }
    scope :accessible_to, -> user {
      if user.nil?
        none
      elsif user.admin? || user.permitted?('droom.library') || user.permitted?('droom.library.read')
        all
      else
        directly_shared_ids = Droom::Share.for_user(user).of_type('Droom::Folder').pluck(:shareable_id)
        legacy_folder_ids = user.personal_folders.pluck(:folder_id)
        granted_folder_ids = directly_shared_ids + legacy_folder_ids
        inherited_folder_ids = where(id: granted_folder_ids).flat_map(&:subtree_ids)
        holder_condition = {
          holder_type: 'Droom::User',
          holder_id: user.id
        }

        where("#{table_name}.id IN (?) OR #{table_name}.created_by_id = ? OR " \
              "(#{table_name}.holder_type = ? AND #{table_name}.holder_id = ?)",
              inherited_folder_ids, user.id, holder_condition[:holder_type], holder_condition[:holder_id])
          .where("#{table_name}.private <> 1 OR #{table_name}.private IS NULL")
      end
    }
    scope :all_private, -> { where("#{table_name}.private = 1") }
    scope :not_private, -> { where("#{table_name}.private <> 1 OR #{table_name}.private IS NULL") }
    scope :all_public, -> { where("#{table_name}.public = 1 AND #{table_name}.private <> 1 OR #{table_name}.private IS NULL") }
    scope :not_public, -> { where("#{table_name}.public <> 1 OR #{table_name}.private = 1)") }
    scope :by_name, -> { order("#{table_name}.name ASC") }
    scope :other_than, -> folders {
      folders = [folders].flatten
      where.not(id: folders.map(&:id))
    }
    scope :visible_to, -> user {
      if user
        select('droom_folders.*')
          .joins('LEFT OUTER JOIN droom_personal_folders AS dpf ON droom_folders.id = dpf.folder_id')
          .where(["(droom_folders.public = 1 OR dpf.user_id = ?)", user.id])
          .group('droom_folders.id')
      else
        all_public
      end
    }

    def automatic?
      holder || !parent && (name == "Events" || name == "Groups")
    end

    def self.home_documents_folder
      find_or_create_by!(name: "Home Documents", ancestry: nil, hidden: true) do |f|
        f.slug = "home-documents"
        f.public = true
      end
    end

    def visible_to?(user)
      return true if self.public?
      return false unless user
      return true if user.admin?
      return true if user.has_folder?(self)
      return false if self.private?
      return true
    end

    def accessible_to?(user)
      self.class.accessible_to(user).where(id: id).exists?
    end

    # A root folder is created automatically for each class that has_folders,
    # the first time something in that class asks for its folder.
    # scope :roots, where('droom_folders.holder_type IS NULL AND droom_folders.ancestry IS NULL')
    #
    scope :loose, -> { where('ancestry IS NULL') }
    scope :latest, -> limit { order("updated_at DESC, created_at DESC").limit(limit) }
    scope :populated, -> {
      select('droom_folders.*')
        .joins(<<~SQL)
          LEFT OUTER JOIN droom_documents AS dd
            ON droom_folders.id = dd.folder_id
          LEFT OUTER JOIN droom_folders AS df
            ON df.ancestry = CASE
                WHEN droom_folders.ancestry IS NULL THEN CAST(droom_folders.id AS CHAR)
                ELSE CONCAT(droom_folders.ancestry, '/', droom_folders.id)
              END
        SQL
        .group('droom_folders.id')
        .having('COUNT(dd.id) > 0 OR COUNT(df.id) > 0')
    }

    def path
      "#{parent.path if parent}/#{slug}"
    end

    def populated?
      children.any? || documents.any?
    end

    def empty?
      !populated?
    end

    def folder_path(fullpath=false)
      folders = is_event? ? [] : [self.name]
      if self.ancestors.present?
        if fullpath
          folders << ancestors.reject{|x| x.holder_type.present? }.map{|x| x.name }.flatten
        else
          folders << ancestors.reject{|x| x.parent_id.nil? || x.holder_type.present?}.map{|x| x.name }.flatten
        end
      end
      "/" + folders.flatten.reverse.join('/')
    end

    def event
      if is_event?
        @event = Droom::Event.find_by_id(holder_id)
      else
        if @folder = ancestors.find{|e| e.is_event?}
          @event = Droom::Event.find(@folder.holder_id)
        end
      end
      @event
    end

    def is_event?
      holder_type == "Droom::Event" && holder_id.present?
    end

    def simple?
      children.empty? && documents.count <= 3
    end

    def family
      subtree
    end

    def loose?
      !parent
    end

    # Most recent activity date considering immediate children.
    def last_modified_at
      dates = [updated_at]
      dates << documents.maximum(:updated_at)
      dates << children.maximum(:updated_at)
      dates.compact.max
    end

    def ancestor_of?(folder)
      folder && folder.ancestors.include?(self)
    end

    def get_name_from_holder
      send :set_properties
      self.save if self.changed?
    end

    def get_event_type
      if holder && holder.is_a?(Droom::Event) && holder.event_type
        holder.event_type
      end
    end

    def confidential?
      confidential = private?
      if et = get_event_type
        confidential ||= et.confidential?
      end
      confidential
    end

    # called from event type or parent folder when confidentiality changes
    def set_confidentiality!(confidentiality)
      if holder and holder.confidential?
        # folder attached to a confidential object will always be confidential,
        #  even if its parent has just been made available.
        confidentiality = true
      end
      assign_attributes private: confidentiality
      save!
    end

    # called before_create
    def inherit_confidentiality
      if holder
        write_attribute :private, holder.confidential?
      elsif parent
        write_attribute :private, parent.confidential?
      end
      true
    end

    # called after_save, including after set_confidentiality!
    def distribute_confidentiality
      documents.each {|document| document.set_confidentiality!(confidential?) }
      children.each {|folder| folder.set_confidentiality!(confidential?) }
    end

    ## Search
    #
    searchkick callbacks: :async, default_fields: [:name], highlight: [:name]
    after_save :reindex

    def search_data
      {
        name: name || "",
        item_type: "folder",
        folder_id: ancestor_ids + [id],
        folder_path: folder_path(true),
        created_by_id: created_by_id,
        modified_at: updated_at,
        confidential: confidential?,
        data_room: self.data_room?
      }
    end

    def set_file_path
      self.documents.map{|m| m.update_columns(file_full_path: m.folder.folder_path.tr(" ", "_")) unless m.file_full_path.nil?}
      unless self.children.empty?
        self.all_children
      end
    end

    def all_children
      self.children.each do |child|
        child.documents.map{|m| m.update_columns(file_full_path: m.folder.folder_path.tr(" ", "_")) unless m.file_full_path.nil?}
        child.all_children
      end
    end

    protected

    def set_properties
      if holder
        if holder.respond_to?(:folder_name)
          self.name ||= holder.folder_name
        else
          self.name ||= holder.name
        end
        self.slug ||= holder.slug
      end

      # pass new or existing slug through uniqueness check as it may have come from user or holder
      base = slug.presence || name || "Folder"
      self.slug = unique_slug(base)

      # folders originally only had slugs, so this could happen too
      self.name ||= self.slug
    end

    # Protect against slug-collision within parent folder scope.
    #
    def unique_slug(base)
      slug = base
      addendum = 0
      skope = parent ? parent.children : Folder.loose
      while skope.other_than(self).find_by(slug: slug)
        addendum += 1
        slug = "#{base}_#{addendum}"
      end
      slug
    end

  end
end
