class Droom::SingleDocument < Droom::DroomRecord
  include Droom::Concerns::Key

  belongs_to :event
  has_one_attached :file

  acts_as_list scope: :event
end
