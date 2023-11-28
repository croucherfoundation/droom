class Droom::DocumentSerializer < ActiveModel::Serializer
  attributes :id,
             :folder_id,
             :folder_name,
             :folder_path,
             :name,
             :file_key,
             :file_url,
             :file_file_name,
             :file_content_type,
             :file_extension,
             :file_full_path,
             :google_doc_link,
             :notion_page_link,
             :position
  
  def file_url
    if object.file.attached?
      object.file.url
    end
  end

  def file_key
    if object.file.attached?
      object.file.key
    end
  end

  def folder_name
    object.folder.name
  end

  def folder_path
    object.folder.path
  end

end
