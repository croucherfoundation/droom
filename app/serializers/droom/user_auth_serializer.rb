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
             :images,
             :preferred_professional_name,
             :preferred_name,
             :preferred_pronoun,
             :user_groups

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
    # I added env checking becuase we are facing rack-time-out error in development mode
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

  def user_groups
    object.groups.pluck(:name) if object.groups.any?
  end

end
