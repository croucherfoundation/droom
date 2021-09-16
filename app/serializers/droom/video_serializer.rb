class Droom::VideoSerializer < ActiveModel::Serializer
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

  def file_name
    object.file_file_name
  end

  def file_type
    object.file_content_type
  end

  def file_size
    object.file_file_size
  end

  def url
    if object.file.attached?
      main_app.url_for(object.file)
    end
  end

  def icon_url
    if object.file.attached?
      main_app.url_for(object.file)
    else
      object.thumbnail_small
    end
  end

  def half_url
    if object.file.attached?
      main_app.url_for(object.file)
    else
      object.thumbnail_medium
    end
  end

  def full_url
    if object.file.attached?
      main_app.url_for(object.file)
    else
      object.thumbnail_large
    end
  end

end
