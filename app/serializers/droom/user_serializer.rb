require 'active_model_serializers'

class Droom::UserSerializer < ActiveModel::Serializer
  attributes :uid,
             :authentication_token,
             :status,
             :title,
             :given_name,
             :family_name,
             :chinese_name,
             :colloquial_name,
             :honours,
             :affiliation,
             :email,
             :emails,
             :phone,
             :phones,
             :address,
             :addresses,
             :country_code,
             :images,
             :confirmed,
             :permission_codes,
             :unconfirmed_email,
             :password_set

  def confirmed
    object.confirmed?
  end

  def password_set
    object.password_set?
  end

  def emails
    object.emails.by_preference.map(&:email)
  end

  def email
    emails.first
  end

  def phones
    object.phones.by_preference.map(&:phone)
  end

  def phone
    phones.first
  end

  def addresses
    object.addresses.by_preference.map(&:address)
  end

  def address
    addresses.first
  end

  def images
    if object.image?
      {
        icon: object.image_url(:icon),
        thumbnail: object.image_url(:thumbnail),
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

end
