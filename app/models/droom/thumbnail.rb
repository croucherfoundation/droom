class Droom::Thumbnail < Droom::DroomRecord
  include Droom::Concerns::Key

  belongs_to :document
  has_one_attached :image

  validates :document_id, presence: true
end
