class Droom::SingleDocument < Droom::DroomRecord
  include Droom::Concerns::Key

  belongs_to :document
  has_one_attached :pdf_single_document
 
  acts_as_list scope: :document

  validates :document_id, presence: true

end
