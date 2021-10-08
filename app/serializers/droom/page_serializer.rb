class Droom::PageSerializer
  include JSONAPI::Serializer

  attributes :id,
             :slug,
             :title,
             :subtitle,
             :content,
             :image_url,
             :thumbnail_url

  attribute :title do |object|
    object.render(:published_title)
  end

  attribute :subtitle do |object|
    object.render(:published_subtitle)
  end

  attribute :content do |object|
    object.render(:published_content)
  end

  attribute :image_url do |object|
    object.published_image.url(:hero) if object.published_image
  end

  attribute :thumbnail_url do |object|
    object.published_image.url(:icon) if object.published_image
  end

end
