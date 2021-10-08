class Droom::TagSerializer
  include JSONAPI::Serializer

  attributes :id, :name, :synonyms

  attribute :name do |object|
    object[:name]
  end

  attribute :synonyms do |object|
    object[:synonyms]
  end
end
