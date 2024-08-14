# This is user as data object: all the fields we need to manage or present the user.
# It does not include authentication information.
#
# Also note btw that the address book is squashed down to one email, one phone and one mobile.
# We don't yet support remote management of all that detail, but users can update their listing,
# which has the effect of adding a new preferred address but not deleting the old.
#
class Droom::UserSerializer < ActiveModel::Serializer
  attributes :uid,
             :status,
             :title,
             :given_name,
             :family_name,
             :chinese_name,
             :name,
             :honours,
             :affiliation,
             :email,
             :email_list,
             :emails,
             :phone,
             :phone_list,
             :mobile,
             :address_list,
             :address,
             :correspondence_address,
             :country_code,
             :images,
             :confirmed,
             :permission_codes,
             :organisation_id,
             :organisation_data,
             :password_set,
             :preferred_pronoun,
             :preferred_professional_name,
             :preferred_name,
             :hkid,
             :dob,
             :pob,
             :nationality,
             :gender

  def name
    object.colloquial_name
  end

  def confirmed
    object.confirmed?
  end

  def password_set
    object.password_set?
  end

  def email_list
    object.emails.pluck(:email).join('; ')
  end

  def emails
    object.emails
  end

  def phone_list
    object.phones.pluck(:phone).join('; ')
  end

  def address_list
    object.addresses.pluck(:address).join('; ')
  end

  def images
    if object.image.attached? && !Rails.env.development?
      {
        icon: object.image_url(:icon),
        thumbnail: object.image_url(:thumb),
        standard: object.image_url(:standard)
      }
    else
      {
        icon: "",
        thumbnail: "",
        standard: ""
      }
    end
  end

  def organisation_data
    Droom::OrganisationSerializer.new(object.organisation).as_json if object.organisation
  end

end
