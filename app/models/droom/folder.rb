require 'zip/zip'

module Droom
  class Folder < ActiveRecord::Base
    attr_accessible :slug, :parent

    belongs_to :created_by, :class_name => Droom.user_class
    belongs_to :holder, :polymorphic => true
    has_many :documents
    has_many :personal_folders
    has_ancestry
    
    validates :slug, :presence => true, :uniqueness_among_siblings => true
    
    before_validation :set_slug
    before_save :set_properties

    scope :visible_to, lambda { |person|
      if person
        select('droom_folders.*')
          .joins('LEFT OUTER JOIN droom_personal_folders AS dpf ON droom_folders.id = dpf.folder_id')
          .where(["(droom_folders.public = 1 OR dpf.person_id = ?)", person.id])
          .group('droom_folders.id')
      else
        all_public
      end
    }
    
    scope :populated, select('droom_folders.*')
      .joins('LEFT OUTER JOIN droom_documents AS dd ON droom_folders.id = dd.folder_id')
      .having('count(dd.id) > 0')
      .group('droom_folders.id')
    
    # These are going to be Droom.* configurable
    scope :all_private, where("secret = 1")
    scope :not_private, where("secret <> 1")
    scope :all_public, where("public = 1 AND secret <> 1")
    scope :not_public, where("public <> 1 OR secret = 1)")

    def name
      holder.name if holder
    end

    def descent
      path.join('/')
    end
    
    def empty?
      documents.empty?
    end
    
    def documents_zipped
      if self.documents.any?
        tempfile = Tempfile.new("droom-temp-#{slug}-#{Time.now}.zip")
        Zip::ZipOutputStream.open(tempfile.path) do |z|
          self.documents.each do |doc|
            z.add(doc.file_file_name, open(doc.file.url))
          end
        end
        tempfile
      end
    end
    
  protected
  
    def set_slug
      self.slug = holder.slug if holder
      true
    end
    
    def set_properties
      self.public = !self.holder
      true
    end
    
  end
end