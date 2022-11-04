module Droom
  class Folder < Droom::DroomRecord
    include ActsAsTree
    # don't use Slugged: we need to apply a dynamic parent scope.

    belongs_to :created_by, :class_name => "Droom::User"
    belongs_to :holder, :polymorphic => true
    has_many :documents, -> {order(position: :asc, file_file_name: :asc)}, :dependent => :destroy
    has_many :personal_folders, :dependent => :destroy
    acts_as_tree :order => "droom_folders.name ASC"

    before_validation :set_properties
    validates :slug, :presence => true, :uniqueness => { :scope => :parent_id }

    default_scope -> { includes(:documents) }

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
    
    def visible_to?(user)
      return true if self.public?
      return false unless user
      return true if user.admin?
      return true if user.has_folder?(self)
      return false if self.private?
      return true
    end

    # A root folder is created automatically for each class that has_folders,
    # the first time something in that class asks for its folder.
    # scope :roots, where('droom_folders.holder_type IS NULL AND droom_folders.parent_id IS NULL')
    #
    scope :loose, -> { where('parent_id IS NULL') }
    scope :latest, -> limit { order("updated_at DESC, created_at DESC").limit(limit) }
    scope :populated, -> {
      select('droom_folders.*')
        .joins('LEFT OUTER JOIN droom_documents AS dd ON droom_folders.id = dd.folder_id LEFT OUTER JOIN droom_folders AS df ON droom_folders.id = df.parent_id')
        .having('count(dd.id) > 0 OR count(df.id) > 0')
        .group('droom_folders.id')
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

    def folder_path
      folders = is_event? ? [] : [self.name]
      if self.ancestors.present?
        folders << ancestors.reject{|x| x.parent_id.nil? || x.holder_type.present?}.map{|x| x.name }.flatten
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
    
    # If we start to get deep folder trees we'll have to use ancestry instead of acts_as_tree.
    def family
      self_and_children
    end
    
    def loose?
      !parent
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
