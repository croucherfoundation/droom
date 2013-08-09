module Droom
  class Scrap < ActiveRecord::Base
    belongs_to :created_by, :class_name => "Droom::User"

    belongs_to :event, :class_name => "Droom::Event", :dependent => :destroy
    accepts_nested_attributes_for :event
    belongs_to :document, :class_name => "Droom::Document", :dependent => :destroy
    accepts_nested_attributes_for :document

    has_attached_file :image, 
                      :styles => {
                        :stream => "1280x1280>",
                        :popup => "1280x1280>",
                        :icon => "32x32#",
                        :thumb => "130x73#"
                      }

    before_save :get_youtube_thumbnail
    after_save :name_associates

    scope :by_date, -> { order("droom_scraps.created_at DESC") }

    scope :later_than, -> scrap { where(["created_at > ?", scrap.created_at]).order("droom_scraps.created_at ASC")  }

    scope :earlier_than, -> scrap { where(["created_at < ?", scrap.created_at]).order("droom_scraps.created_at DESC")  }

    scope :matching, -> fragment {
      fragment = "%#{fragment}%"
      where('droom_scraps.name LIKE :f OR droom_scraps.body LIKE :f OR droom_scraps.note LIKE :f', :f => fragment)
    }
    
    scope :visible_to, -> user { where("1=1") }

    default_scope -> { order("created_at DESC").includes(:event, :document) }

    Droom.scrap_types.each do |t|
      scope t.pluralize.to_sym, -> { where(:scraptype => t.to_s) }
    end

    def wordiness
      if body.length < 48
        'word'
      elsif body.length < 320
        'phrase'
      elsif body.length < 800
        'paragraph'
      else
        'text'
      end
    end

    def text_size
      if l = body.length
        ((560.0/(1.4 * l+150.0)) + 0.25) / 1.5
      else
        1
      end
    end
    
    def url_with_protocol
      body =~ /^https?:\/\// ? body : "http://#{body}"
    end

    def url_without_protocol
      body.sub(/^https?:\/\//, '')
    end

    def as_search_result
      {
        :type => 'scrap',
        :prompt => name,
        :value => name,
        :id => id
      }
    end
    
    def next_younger
      Droom::Scrap.later_than(self).first
    end
    
    def next_older
      Droom::Scrap.earlier_than(self).first
    end

  protected
  
    def get_youtube_thumbnail
      if scraptype == "video" && youtube_id?
        self.image = URI("http://img.youtube.com/vi/#{youtube_id}/0.jpg")
      end
    end
    
    def name_associates
      event.update_column(:name, name) if event
      document.update_column(:name, name) if document
    end
    
  end
end