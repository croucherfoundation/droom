module Droom
  class Link < Droom::DroomRecord
    default_scope { order(name: :asc) }
  end
end
