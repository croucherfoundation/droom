class Droom::AddressSerializer < ActiveModel::Serializer
  attributes :id, 
             :address, 
             :address_type_id, 
             :user_id,
             :address_type

  belongs_to :user

  def address_type
    object&.address_type&.name
  end
end
