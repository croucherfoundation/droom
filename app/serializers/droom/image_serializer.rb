class Droom::ImageSerializer
  include JSONAPI::Serializer

  attributes :id,
             :file,
             :file_name,
             :remote_url,
             :file_size,
             :width,
             :height,
             :file_type,
             :file_updated_at,
             :url,
             :icon_url,
             :half_url,
             :full_url,
             :hero_url

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
    object.url(:original).presence || ""
  end

  attribute :icon_url do |object|
    object.url(:icon).presence || ""
  end

  attribute :half_url do |object|
    object.url(:half).presence || ""
  end

  attribute :full_url do |object|
    object.url(:full).presence || ""
  end

  attribute :hero_url do |object|
    object.url(:hero).presence || ""
  end

end
