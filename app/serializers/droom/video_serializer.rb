class Droom::VideoSerializer
  include JSONAPI::Serializer

  attributes :id,
             :file_name,
             :remote_url,
             :provider,
             :file_type,
             :file_size,
             :width,
             :height,
             :duration,
             :file_updated_at,
             :embed_code,
             :url,
             :icon_url,
             :half_url,
             :full_url

  attribute :file_name do |object|
    object.file_file_name
  end

  attribute :file_type do |object|
    object.file_content_type
  end

  attribute :file_size do |object|
    object.file_file_size
  end

  attribute :url do |object|
    if object.file.attached?
      object.file.url
    end
  end

  attribute :icon_url do |object|
    if object.file.attached?
      object.file.url
    else
      object.thumbnail_small
    end
  end

  attribute :half_url do |object|
    if object.file.attached?
      object.file.url
    else
      object.thumbnail_medium
    end
  end

  attribute :full_url do |object|
    if object.file.attached?
      object.file.url
    else
      object.thumbnail_large
    end
  end

end
