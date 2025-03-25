# require 'combine_pdf'
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
    temp_pdf_pages = split_pdf_pages(pdf_tempfile, total_pages)

    attach_thumbnails_and_pdfs(temp_thumbnails, temp_pdf_pages)

    # Cleanup temp files
    pdf_tempfile.unlink
    temp_thumbnails.each { |path| File.delete(path) }
    temp_pdf_pages.each { |path| File.delete(path) }

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

  def split_pdf_pages(pdf_tempfile, total_pages)
    temp_pdfs = []
    pdf = CombinePDF.load(pdf_tempfile.path)
    
    (0...total_pages).each do |page_number|
      single_page_pdf = CombinePDF.new
      single_page_pdf << pdf.pages[page_number] # Extract each page

      pdf_one_tempfile = Tempfile.new(["pdf_page_#{page_number}", ".pdf"])
      
      single_page_pdf.save(pdf_one_tempfile.path)
    
      temp_pdfs << pdf_one_tempfile.path
    end

    temp_pdfs
  end

  def attach_thumbnails_and_pdfs(temp_thumbnails, temp_pdf_pages)
    temp_thumbnails.each_with_index do |thumbnail_path, index|
      thumbnail = thumbnails.create!(
        page_number: index + 1, # Ensure page numbering starts at 1
        image: {
          io: File.open(thumbnail_path),
          filename: "thumbnail_#{index + 1}.jpg",
          content_type: "image/jpeg"
        }
      )
    end
    temp_pdf_pages.each_with_index do |pdf_path, index|
      pdf_page = thumbnails.create!(
        page_number: index + 1,
        pdf_single_page: {
          io: File.open(pdf_path),
          filename: "pdf_#{index + 1}.pdf",
          content_type: "application/pdf"
        }
      )
    end
  end
end
