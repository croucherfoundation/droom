class Droom::Thumbnail < Droom::DroomRecord
  include Droom::Concerns::Key

  belongs_to :document
  has_one_attached :image
  has_one_attached :pdf_single_page # Store each page as a single PDF


  validates :document_id, presence: true
end
