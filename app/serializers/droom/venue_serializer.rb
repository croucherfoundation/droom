class Droom::VenueSerializer
  include JSONAPI::Serializer
  
  attributes :id, :name, :slug, :definite_name, :description, :address, :post_code, :country_code, :lat, :lng
end
