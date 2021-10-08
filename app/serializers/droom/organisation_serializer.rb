class Droom::OrganisationSerializer
  include JSONAPI::Serializer
  
  attributes :id,
             :name,
             :chinese_name,
             :description,
             :phone,
             :address,
             :owner_id,
             :organisation_type_id,
             :url,
             :facebook_page,
             :facebook_url,
             :twitter_id,
             :twitter_url,
             :instagram_id,
             :instagram_url,
             :weibo_id,
             :weibo_url,
             :logo_url,
             :image_url

end
