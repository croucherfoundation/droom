
module Droom::Api::Ex
  class UserSerializer < ActiveModel::Serializer
    type :user

    attributes  :uid,
                :title,
                :name,
                :emails,
                :image,

    def emails
      object.emails.map(&:email).join(', ')
    end
 
    def image
      object.image.url rescue ""
    end
  end
end
