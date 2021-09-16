class Droom::UserAuthSerializer < ActiveModel::Serializer
  attributes :uid,
             :unique_session_id,
             :status,
             :name,
             :title,
             :given_name,
             :family_name,
             :chinese_name,
             :honours,
             :email,
             :phone,
             :mobile,
             :address,
             :confirmed,
             :permission_codes,
             :password_set,
             :images

  def name
    object.colloquial_name
  end

  def confirmed
    object.confirmed?
  end

  def password_set
    object.password_set?
  end

  def images
    if object.image.attached?
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
