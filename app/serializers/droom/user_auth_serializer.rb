class Droom::UserAuthSerializer
  include JSONAPI::Serializer

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
             :preferred_pronoun,
             :user_groups

  attribute :name do |object|
    object.colloquial_name
  end

  attribute :confirmed do |object|
    object.confirmed?
  end

  attribute :password_set do |object|
    object.password_set?
  end

  attribute :images do |object|
    if object.image.attached?
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
