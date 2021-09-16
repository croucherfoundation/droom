module Droom::Concerns::Imaged
  extend ActiveSupport::Concern

  included do
    has_one_attached :image
  end

  ## Images
  #
  def image_url(style=:standard, decache=true)
    if image.attached?
      url = image.url(style, decache)
      url.sub(/^\//, "#{Settings.protocol}://#{Settings.host}/")
    else
      ""
    end
  end

  # Images usually come to us as data: urls but can also be given as actual url or assigned directly to image.
  #
  def image_url=(address)
    if address.present?
      self.image = URI(address)
    end
  rescue OpenURI::HTTPError => e
    Rails.logger.warn "Cannot read image url #{address} because: #{e}. Skipping."
  end

  # image_data should be a fully specified data: url in base64 with prefix. Paperclip knows what to do with it.
  #
  def image_data=(data_uri)
    if data_uri.present?
      self.image = data_uri
    end
  end

  # If image_data is given then the file name should be also supplied as `image_name`.
  # You normally want to call this method after image_url= or image_data=, eg by ordering
  # parameters in the controller.
  #
  def image_name=(name)
    self.image_file_name = name
  end

  def thumbnail
    image_url(:thumb)
  end

  def icon
    image_url(:icon)
  end

end
