class Droom::Thumbnail < Droom::DroomRecord
  include Droom::Concerns::Key

  belongs_to :event
  has_one_attached :image

  acts_as_list scope: :event
end
