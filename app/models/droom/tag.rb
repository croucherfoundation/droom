#TODO review droom_client treatment of tags, especially the get-me-everything caching.

# Droom tags are simple one word flags that can have a type and some synonyms.
# They are usually presented in a choose-or-create typeahead interface
# and can be attached to any model class by including the `Droom::Concerns::Tagged` concern.

module Droom
  class Tag < Droom::DroomRecord

    has_many :taggings
    has_many :taggees, :through => :taggings
    has_many :tag_synonyms
    belongs_to :tag_type, optional: true

    before_save :downcase

    scope :other_than, -> term {
      where.not(name: term)
    }

    scope :of_type, -> names {
      joins(:tag_type).where(droom_tag_types: {name: names}).order(:name)
    }

    scope :by_term, -> {
      order(name: :asc)
    }

    def self.find_or_create(term)
      if term.present?
        where(name: term.strip.downcase).first_or_create
      end
    end

    def self.from_list(list=[], or_create=true)
      list = list.split(/[,;]\s*/) if list.is_a? String
      list.uniq.map { |t| find_or_create(t) }
    end

    def self.to_list(tags=[])
      tags.map(&:name).compact.uniq.join(', ')
    end


    ## Elasticsearch indexing
    #
    searchkick _all: false, default_fields: [:name, :synonyms], word_start: [:name, :synonyms]

    def search_data
      {
        name: name,
        synonyms: synonyms
      }
    end

    def synonyms
      tag_synonyms.pluck(:synonym).uniq
    end

    def with_synonyms
      [name] + synonyms
    end

    def subsume(other_tag=nil)
      Droom::Tag.transaction do
        if other_tag && other_tag != self
          self.taggees << other_tag.taggees
          self.tag_synonyms << other_tag.tag_synonyms
          self.tag_synonyms.create(synonym: other_tag.name)
          other_tag.destroy
          self.save
        end
      end
    end

    # This is here just to make tag interpolation a bit more readable.
    #
    def to_s
      name
    end

    ## Clouds
    #
    # The administrative interface offers a big tag cloud and drag and drop tag-merging. Tag size in the
    # cloud is based on a usage count that is retrieved here in a join with the taggings table. The cloud
    # display logic can be found in the [application_helper](../controllers/application_helper.html).
    #
    attr_accessor :cloud_size
    scope :with_usage_count, -> limit {
      select("tags.*, count(tt.id) AS weight").joins("INNER JOIN taggings as tt ON tt.tag_id = tags.id").group("tt.tag_id").order("weight DESC").limit(limit)
    }

    # *self.for_cloud* uses that scope to return a list of the most popular tags, weighted for display as a tag cloud
    # and re-sorted into alphabetical order (since to select the most popular we originally had to sort by weighting).
    #
    def self.for_cloud(limit=100)
      with_usage_count(limit).sort_by(&:name)
    end











    ## RETRO
    #
    ## Suggestions
    #
    # There is a tag-suggesting mechanism in the front end to encourage tag reuse and consistency.
    # It rests on this simple scope, which returns all tags matching a given string fragment.
    #
    scope :matching, -> fragment {
      fragment = "%#{fragment}%"
      where('tags.name like ?', fragment)
    }
  
    # The public-facing search engine is faceted and relies on a similar but broader suggestion mechanism
    # that offers both tags and institutions. In that situation we only want to display tags that will give
    # give results, so we limit the suggestions to only those tags that have been applied to a user.
    #
    scope :in_use, -> {
      joins("INNER JOIN taggings ON taggings.tag_id = tags.id")
      .group('tags.id')
      .having('count(taggings.tag_id) > 0')
    }

    # This returns a list of all the tags attached to any of a given set of objects.
    # In future it will support cloud-weighting. 
    #
    scope :attached_to_any_of, -> these {
      these = [these].flatten
      type = these.first.class.to_s
      placeholders = these.map{"?"}.join(',')
      select("droom_tags.*, count(droom_taggings.id) as use_count")
        .joins("INNER JOIN droom_taggings ON droom_taggings.tag_id = droom_tags.id")
        .where(["droom_taggings.taggee_type = ? and droom_taggings.taggee_id IN (#{placeholders})", *these.map(&:id).unshift(type)])
        .group('droom_tags.id')
    }
    

    ## VERY RETRO
    #
    # Suggestions are returned in a minimal format and need only contain name and (for the public search
    # where there are more possibilities) the type of suggestion.
    #
    def as_json(options={})
      {
        :id => id,
        :name => name,
        :type => 'tag'
      }
    end



  protected
  
    def downcase
      self.name = self.name.downcase
    end

  end
end