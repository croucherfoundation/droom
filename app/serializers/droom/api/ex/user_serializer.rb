
module Droom::Api::Ex
  class UserSerializer < ActiveModel::Serializer
    type :user

    attributes  :uid,
                :title,
                :name,
                :emails,
                :image,
                :groups

    def emails
      object.emails.map(&:email).join(', ')
    end

    def image
      object.image.url rescue ""
    end

    def groups
      object.groups.map(&:name)
    end
  end
end
