class Droom::FolderSerializer < ActiveModel::Serializer
  attributes :id,
             :name,
             :parent_id
end
