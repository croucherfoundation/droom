# Event type is currenty our only source of confidentiality, which it distributes through its event-folders to their documents.
#
module Droom
  class EventType < Droom::DroomRecord
    include Droom::Concerns::Slugged

    has_many :events, :dependent => :nullify
    has_many :folders, through: :events

    has_folder within: "Events" # here the within arguments sets the name of our parent folder

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

    def cover_text_lookup
      {
        2 => "An Investment Committee Meeting is to be held on",
        3 => "An Audit Committee Meeting is to be held on",
        6 => "A meeting of the CF Nomination & Remuneration Committee is to be held on",
        9 => "A Trustees’ Meeting is to be held on",
        10 => "A Governors’ Meeting is to be held on",
        11 => "A meeting of the Academic Assessment Working Group is to be held on",
        12 => "A meeting of the NCF Nomination Committee is to be held on"
      }
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
