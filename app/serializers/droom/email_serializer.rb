class Droom::EmailSerializer < ActiveModel::Serializer
  attributes :id, 
             :user_id, 
             :email, 
             :default, 
             :address_type_id,
             :address_type

  def address_type
    object&.address_type&.name
  end
end
