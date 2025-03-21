require 'mini_magick'
require 'open-uri'

module Droom::Concerns::PdfThumbnailable
  extend ActiveSupport::Concern

  included do
    has_many :thumbnails, dependent: :destroy
  end

  def generate_thumbnails
    return unless file.attached?

    pdf_tempfile = download_pdf
    total_pages = get_pages(pdf_tempfile)
    temp_thumbnails = convert_to_images(pdf_tempfile, total_pages)

    attach_thumbnails(temp_thumbnails)

    # Cleanup temp files
    pdf_tempfile.unlink
    temp_thumbnails.each { |path| File.delete(path) }

  end

  def download_pdf
    pdf_tempfile = Tempfile.new(["pdf_preview", ".pdf"])
    pdf_tempfile.binmode
    pdf_tempfile.write(file.download)
    pdf_tempfile.close
    pdf_tempfile
  end

  def get_pages(pdf_tempfile)
    pdf_info = MiniMagick::Image.open(pdf_tempfile.path)
    pdf_info.pages.length rescue 1
  end

  def convert_to_images(pdf_tempfile, total_pages)
    temp_thumbnails = []

    (0...total_pages).each do |page_number|
      thumbnail_tempfile = Tempfile.new(["pdf_thumbnail_#{page_number}", ".jpg"])
      thumbnail_tempfile.close

      # Using the updated 'magick' command for IMv7
      MiniMagick::Tool::Magick.new do |magick|
        magick.density '150'
        magick.quality '100'
        magick << "#{pdf_tempfile.path}[#{page_number}]" # Extract each page
        magick << thumbnail_tempfile.path
      end

      temp_thumbnails << thumbnail_tempfile.path
    end

    temp_thumbnails
  end

  def attach_thumbnails(temp_thumbnails)
    temp_thumbnails.each_with_index do |thumbnail_path, index|
      thumbnails.create!(
        page_number: index + 1, # Ensure page numbering starts at 1
        image: {
          io: File.open(thumbnail_path),
          filename: "thumbnail_#{index + 1}.jpg",
          content_type: "image/jpeg"
        }
      )
    end
  end
end
