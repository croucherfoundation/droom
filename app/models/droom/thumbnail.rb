class Droom::Thumbnail < Droom::DroomRecord
  include Droom::Concerns::Key

  belongs_to :event
  belongs_to :document, optional: true
  has_one_attached :image

  acts_as_list scope: :event

  def single_document
    event.single_documents.find_by(position: position)
  end
end
