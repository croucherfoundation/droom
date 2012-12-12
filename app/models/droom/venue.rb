require 'snail'

module Droom
  class Venue < ActiveRecord::Base
    attr_accessible :name, :lat, :lng, :post_line1, :post_line2, :post_city, :post_country, :post_code
    
    belongs_to :created_by, :class_name => 'User'
    has_many :events, :dependent => :nullify
    acts_as_mappable

    default_scope :order => 'name asc'
    before_validation :geocode_and_get_address

    scope :name_matching, lambda { |fragment| 
      fragment = "%#{fragment}%"
      where('droom_venues.name like ?', fragment)
    }

    def self.visible_to(person=nil)
      self.scoped({})
    end

    # *for_selection* returns a set of [name, id] pairs suitable for use as select options.
    def self.for_selection
      self.all.map{|v| [v.proper_name, v.id] }
    end

    def proper_name
      if prepend_article?
        "the #{name}"
      else
        name
      end
    end

    def to_s
      name
    end
    
    def identifier
      'venue'
    end
    
    # Snail is a library that abstracts away - as far as possible - the vagaries of international address formats. Here we map our data columns onto Snail's abstract representations so that they can be rendered into the correct format for their country.
    def address
      Snail.new(
        :line_1 => post_line1,
        :line_2 => post_line2,
        :city => post_city,
        :region => post_region,
        :postal_code => post_code,
        :country => post_country
      )
    end

    def address?
      post_line1? && post_city
    end

    def as_json(options={})
      json = {
        :id => id,
        :name => name,
        :postcode => post_code,
        :address => address.to_s,
        :lat => lat,
        :lng => lng,
        :events => events.visible_to(options[:person]).as_json(options)
      }
    end

    def as_suggestion
      {
        :type => 'venue',
        :prompt => name,
        :value => name,
        :id => id
      }
    end

    def as_ri_cal_calendar
      RiCal.Calendar do |cal|
        events.primary.each do |event|
          cal.add_subcomponent(event.to_ri_cal)
        end
      end
    end

    def to_ical
      self.as_ri_cal_calendar.to_s
    end

    # We only go back to google for a new map location if there has been a change of address, but there are many places in which that could happen.
    #
    def address_changed?
      name_changed? || post_line1_changed? || post_line2_changed? || post_city_changed? || post_region_changed?  || post_code_changed? || post_country_changed?
    end

  private


  end
end