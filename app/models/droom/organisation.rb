module Droom
  class Organisation < ActiveRecord::Base
    has_many :users
    belongs_to :owner, :class_name => 'Droom::User'
    belongs_to :created_by, :class_name => 'Droom::User'
    
    scope :added_since, -> date { where("created_at > ?", date)}

    default_scope -> {order("name ASC")}

    def self.for_selection
      organisations = self.order("name asc").map{|f| [f.name, f.id] }
      organisations.unshift(['', ''])
      organisations
    end

    def url_with_protocol
      url =~ /^https?:\/\// ? url : "http://#{url}"
    end

    def url_without_protocol
      url.sub(/^https?:\/\//, '')
    end
  end
end