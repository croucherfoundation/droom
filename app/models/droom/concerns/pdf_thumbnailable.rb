# require 'combine_pdf'
require 'mini_magick'
require 'open-uri'

module Droom::Concerns::PdfThumbnailable
  extend ActiveSupport::Concern

  included do
    has_many :thumbnails, dependent: :destroy
    has_many :single_documents, dependent: :destroy
  end

  def generate_thumbnails(file_path)
    return unless file_path.present?

    pdf_tempfile = file_path
    total_pages = get_pages(pdf_tempfile)
    temp_thumbnails = convert_to_images(pdf_tempfile, total_pages)
    temp_pdf_pages = split_pdf_pages(pdf_tempfile, total_pages)

    attach_thumbnails_and_pdfs(temp_thumbnails, temp_pdf_pages)

    # Cleanup temp files
    temp_thumbnails.each { |path| File.delete(path) }
    temp_pdf_pages.each { |path| File.delete(path) }

  end

  def get_pages(pdf_tempfile)
    pdf_info = MiniMagick::Image.open(pdf_tempfile)
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
        magick << "#{pdf_tempfile}[#{page_number}]" # Extract each page
        magick << thumbnail_tempfile.path
      end

      temp_thumbnails << thumbnail_tempfile.path
    end

    temp_thumbnails
  end

  def split_pdf_pages(pdf_tempfile, total_pages)
    temp_pdfs = []
    pdf = CombinePDF.load(pdf_tempfile)

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
      thumbnail = self.thumbnails.create!(
        image: {
          io: File.open(thumbnail_path),
          filename: "thumbnail_#{index + 1}.jpg",
          content_type: "image/jpeg"
        }
      )
    end
    temp_pdf_pages.each_with_index do |pdf_path, index|
      pdf_page = self.single_documents.create!(
        file: {
          io: File.open(pdf_path),
          filename: "pdf_#{index + 1}.pdf",
          content_type: "application/pdf"
        }
      )
    end
  end
end
