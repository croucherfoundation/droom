module Droom::Concerns::Tagged
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggee, class_name: "Droom::Tagging"
    has_many :tags, through: :taggings, class_name: "Droom::Tag"
  end

  class_methods do
    def tagged_like(thing, options={})
      with_tags_like thing.tag_names, options
    end

    def tagged_at_all_like(thing, options={})
      with_any_tag thing.tag_names, options
    end

    def with_tags_like(tags, options={})
      bool_query = {
        should: tags.map { |tag_name| {term: { tags: tag_name } }}
      }
      if options[:since]
        bool_query[:filter] = {range: { created_at: {gte: options[:since]} }}
      end
      args = { body: {
        query: { bool: bool_query },
        sort: options[:recent] ? [{ updated_at: { order: "desc" }}] : "_score"
      }}
      args[:limit] = options[:limit] if options[:limit]
      args[:offset] = options[:offset] if options[:offset]
      self.search **args
    end

    def with_any_tag(tags, options={})
      self.search where: {tags: tags}
    end
  end

  def tag_list
    tag_names.join(",")
  end

  def tag_names
    tags.map(&:name).uniq
  end

  def tags_with_synonyms
    tags.includes(:tag_synonyms).map(&:with_synonyms).flatten.uniq.join(' ')
  end

  def tag_list=(tag_list)
    self.tags = tag_list.split(/,\s*/).map { |t| Tag.find_or_create(t) }
  end

  # To support ancient keywords= interface

  def keywords
    self.tags.pluck(:name).compact.uniq.join(', ')
  end

  def keywords_before_type_cast   # for form_helper
    keywords
  end

  def keywords=(somewords="")
    if somewords.blank?
      self.tags.clear
    else
      self.tags = Droom::Tag.from_list(somewords)
    end
  end

end
