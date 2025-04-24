require 'mini_magick'
require 'combine_pdf'
require 'open-uri'

module Droom::Concerns::PdfThumbnailable
  extend ActiveSupport::Concern

  included do
    has_many :thumbnails, dependent: :destroy
    has_many :single_documents, dependent: :destroy
  end

  def generate_thumbnails(file_path)
    return unless file_path.present?

    begin
      total_pages = get_total_pages(file_path)

      # Process page-by-page to reduce memory usage
      (0...total_pages).each do |page_number|
        thumbnail_path = convert_page_to_image(file_path, page_number)
        pdf_page_path  = extract_single_pdf_page(file_path, page_number)

        attach_thumbnail(thumbnail_path, page_number)
        attach_pdf_page(pdf_page_path, page_number)

        cleanup_file(thumbnail_path)
        cleanup_file(pdf_page_path)
      end
    rescue => e
      Rails.logger.error("PDF processing failed: #{e.message}")
    end
    Rails.logger.info("PDF processing complete: #{total_pages} pages")
  end

  def get_total_pages(pdf_tempfile)
    CombinePDF.load(pdf_tempfile).pages.count
  rescue => e
    Rails.logger.error("Error reading PDF page count: #{e.message}")
    1
  end

  def convert_page_to_image(pdf_tempfile, page_number)
    output = Tempfile.new(["thumb_#{page_number}", ".jpg"])
    output.close # allow ImageMagick to write

    MiniMagick::Tool::Magick.new do |magick|
      magick.density '100'
      magick.quality '85'
      magick << "#{pdf_tempfile}[#{page_number}]"
      magick << output.path
    end

    output.path
  end

  def extract_single_pdf_page(pdf_tempfile, page_number)
    pdf = CombinePDF.load(pdf_tempfile)
    single_page_pdf = CombinePDF.new
    single_page_pdf << pdf.pages[page_number]

    output = Tempfile.new(["pdf_page_#{page_number}", ".pdf"])
    output.close
    single_page_pdf.save(output.path)

    output.path
  end

  def attach_thumbnail(thumbnail_path, page_number)
    self.thumbnails.create!(
      image: {
        io: File.open(thumbnail_path),
        filename: "event_#{self.id}_thumbnail_#{page_number + 1}.jpg",
        content_type: "image/jpeg"
      }
    )
  end

  def attach_pdf_page(pdf_path, page_number)
    self.single_documents.create!(
      file: {
        io: File.open(pdf_path),
        filename: "event_#{self.id}_pdf_page_#{page_number + 1}.pdf",
        content_type: "application/pdf"
      }
    )
  end

  def cleanup_file(path)
    File.delete(path) if path && File.exist?(path)
  rescue => e
    Rails.logger.warn("Cleanup failed for #{path}: #{e.message}")
  end
end
