
module Droom::Api::Ex
  class UserSerializer < ActiveModel::Serializer
    type :user

    attributes  :uid,
                :title,
                :name,
                :emails

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
  end
end
