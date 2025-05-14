class Droom::SingleDocument < Droom::DroomRecord
  include Droom::Concerns::Key

  belongs_to :event
  belongs_to :document, optional: true
  has_one_attached :file

  acts_as_list scope: :event

  def thumbnail
    event.thumbnails.find_by(position: position)
  end
end
