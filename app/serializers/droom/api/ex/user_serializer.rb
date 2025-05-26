
module Droom::Api::Ex
  class UserSerializer < ActiveModel::Serializer
    type :user

    attributes  :uid,
                :title,
                :name,
                :emails,
                :images,

    def uid
      object[:uid]
    end

    def title
      object[:title]
    end

    def name
      object[:name]
    end

    def emails
      object[:emails]
    end

    def images
      user_object = Droom::User.find_by(uid: object[:uid])
      if user_object&.image&.attached?
        {
          icon: user_object.image_url(:icon),
          thumbnail: user_object.image_url(:thumb),
          standard: user_object.image_url(:standard)
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
end
