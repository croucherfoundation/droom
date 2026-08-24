# Event type is currenty our only source of confidentiality, which it distributes through its event-folders to their documents.
#
module Droom
  class EventType < Droom::DroomRecord
    include Droom::Concerns::Slugged
    include Droom::RichText::OptIn

    has_many :events, :dependent => :nullify
    has_many :folders, through: :events

    has_folder within: "Events" # here the within arguments sets the name of our parent folder

    rich_text_attributes :description
    before_validation :sanitize_rich_text_attributes!, if: -> { description.present? }

    before_validation :slug_from_name
    after_save :distribute_confidentiality

    default_scope -> {order(:name)}

    def self.for_selection
      self.all.map {|et| [et.name, et.id]}
    end
    
    def self.default
      default_type = self.where(:slug => "other_events").first_or_initialize
      if default_type.new_record?
        default_type.name = "Other Events"
        default_type.save
      end
      default_type
    end

    def confidential?
      private?
    end

    protected

    # This is done in a cascading way so that we trigger all the right reindexings.
    # It should be a rare and special event, and we prefer thorough to quick.
    #
    def distribute_confidentiality
      folder.set_confidentiality!(private?)
      # catch any event folders in the wrong place
      folders.other_than(folder.family).each {|folder| folder.set_confidentiality!(private?) }
    end

  end
end