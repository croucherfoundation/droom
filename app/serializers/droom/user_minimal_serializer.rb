# This is user as data object: all the fields we need to manage or present the user.
# It does not include authentication information.
#
# Also note btw that the address book is squashed down to one email, one phone and one mobile.
# We don't yet support remote management of all that detail, but users can update their listing,
# which has the effect of adding a new preferred address but not deleting the old.
#
class Droom::UserMinimalSerializer < ActiveModel::Serializer
  attributes :uid,
             :email_list,
             :phone_list,
             :address_list,
             :timezone

  def email_list
    object.emails.map do |email|
      {
        id: email.id,
        email: email.email,
        email_type: email.address_type&.name
      }
    end
  end

  def phone_list
    object.phones.map do |phone|
      {
        id: phone.id,
        phone: phone.phone,
        phone_type: phone.address_type&.name
      }
    end
  end

  def address_list
    object.addresses.map do |address|
      {
        id: address.id,
        address: address.address,
        address_type: address.address_type&.name
      }
    end
  end


end
