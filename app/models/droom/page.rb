require 'mustache'

module Droom
  class Page < ApplicationRecord
    include Droom::Concerns::Slugged

    attr_accessor :publish_now, :publishing
    after_save :publish_if_publishing

    belongs_to :main_image, class_name: "Droom::Image"
    belongs_to :published_image, class_name: "Droom::Image"

    validates :slug, uniqueness: true
    before_validation :slug_from_title

    scope :published, -> {
      where.not(published_at: nil)
    }

    def illustrated?
      !!main_image
    end

    def render_fragment(file)
      proc {
        ApplicationController.renderer.render(partial: "droom/pages/fragments/#{file}").html_safe
      }
    end

    def publish!
      unless publishing?
        update_attributes({
          published_title: title,
          published_subtitle: subtitle,
          published_image_id: main_image_id,
          published_content: content,
          published_at: Time.now
        })
      end
    end

    def published?
      published_at?
    end

    def publish_now?
      !!publish_now
    end

    def publishing?
      !!publishing
    end

    def publication_required?
      !published_at || published_at < updated_at
    end

    def render(attribute=:published_content)
      if renderable_attributes.include? attribute
        Mustache.render(read_attribute(attribute), interpolations)
      else
        ""
      end
    end

    def interpolations
      {
        site_title: I18n.t('site_title')
      }.merge custom_interpolations
    end

    def custom_interpolations
      {}
    end

    protected

    def renderable_attributes
      [:title, :published_title, :subtitle, :published_subtitle, :content, :published_content]
    end

    def publish_if_publishing
      publish! if publish_now?
    end

  end
end
