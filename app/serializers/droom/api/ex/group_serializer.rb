
module Droom::Api::Ex
  class GroupSerializer < ActiveModel::Serializer
    type :group

    attributes  :id,
                :name,
                :slug,
                :description

  end
end
