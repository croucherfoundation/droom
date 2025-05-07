require 'mini_magick'
require 'combine_pdf'
require 'open-uri'

module Droom::Concerns::PdfThumbnailable
  extend ActiveSupport::Concern

  included do
    has_many :thumbnails, dependent: :destroy
    has_many :single_documents, dependent: :destroy
  end

  require 'tempfile'

  def generate_pdf_cover
    pdf_html = ::ApplicationController.renderer.new.render_to_string(
      template: 'droom/events/compile_pdf/cover',
      layout:   'compile_pdf',
      assigns:  { event: self }
    )

    pdf_file = WickedPdf.new.pdf_from_string(
      pdf_html,
      orientation: 'Portrait',
      page_size:   'A4',
      margin:      { top: 0, bottom: 0, left: 0, right: 0 },
      disable_smart_shrinking: true,
      zoom: 1,
      print_media_type: true,
      background: true
    )

    tempfile = Tempfile.new(["cover_#{id}", ".pdf"], binmode: true)
    tempfile.write(pdf_file)
    tempfile.rewind

    generate_thumbnails(tempfile.path, is_cover: true)
  end

  def generate_thumbnails(file_path, options={is_cover: false})
    return unless file_path.present?

    @is_cover = options[:is_cover]
    @document_id = options[:document_id]

    total_pages = get_total_pages(file_path)
    process_pdf_pages(file_path, total_pages)
  end

  private

  def get_total_pages(pdf_tempfile)
    CombinePDF.load(pdf_tempfile).pages.count
  rescue => e
    Rails.logger.error("Error reading PDF page count: #{e.message}")
    1
  end

  def process_pdf_pages(file_path, total_pages)
    (0...total_pages).each do |page_number|
      generate_page(file_path, page_number)
    end
  rescue => e
    Rails.logger.error("PDF processing failed: #{e.message}")
  ensure
    Rails.logger.info("PDF processing complete: #{total_pages} pages")
  end

  def generate_page(file_path, page_number)
    thumbnail_path = convert_page_to_image(file_path, page_number)
    attach_thumbnail(thumbnail_path, page_number)
    cleanup_file(thumbnail_path)

    pdf_page_path = extract_single_pdf_page(file_path, page_number)
    attach_pdf_page(pdf_page_path, page_number)
    cleanup_file(pdf_page_path)
  end

  def convert_page_to_image(pdf_tempfile, page_number)
    output = Tempfile.new(["thumb_#{page_number}", ".jpg"])
    output.close

    MiniMagick::Tool::Convert.new do |magick|
      magick.density '100'
      magick.quality '100'
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
    if @is_cover
      if thumbnail = self.thumbnails&.find_by(is_cover: true)
        thumbnail.image.attach(
          io: File.open(thumbnail_path),
          filename: "event_#{self.id}_thumbnail_#{page_number + 1}.jpg",
          content_type: "image/jpeg"
        )
        return
      end
    end

    self.thumbnails.create!(
      is_cover: @is_cover,
      document_id: @document_id,
      image: {
        io: File.open(thumbnail_path),
        filename: "event_#{self.id}_thumbnail_#{page_number + 1}.jpg",
        content_type: "image/jpeg"
      }
    )
  end

  def attach_pdf_page(pdf_path, page_number)
    if @is_cover
      if pdf = self.single_documents&.find_by(is_cover: true)
        pdf.file.attach(
          io: File.open(pdf_path),
          filename: "event_#{self.id}_pdf_page_#{page_number + 1}.pdf",
          content_type: "application/pdf"
        )
        return
      end
    end

    self.single_documents.create!(
      is_cover: @is_cover,
      document_id: @document_id,
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

  def download_to_tempfile(document)
    attachment = document.file
    blob = attachment.blob

    tempfile = Tempfile.new(["attachment", File.extname(blob.filename.to_s)])
    tempfile.binmode
    tempfile.write(blob.download)
    tempfile.rewind
    tempfile.path
  end

  def convert_docx_to_pdf(input_path)
    output_dir = File.dirname(input_path)

    Docsplit.extract_pdf(input_path, output: output_dir)

    pdf_path = File.join(output_dir, "#{File.basename(input_path, '.*')}.pdf")
    raise "PDF not generated" unless File.exist?(pdf_path)

    pdf_path
  end

  def convert_image_to_pdf(image_path)
    output_path = File.join(File.dirname(image_path), "#{File.basename(image_path, '.*')}.pdf")

    MiniMagick::Tool::Convert.new do |convert|
      convert.density '150'
      convert.units 'PixelsPerInch'
      convert << image_path
      convert.resize '1240x1754>'
      convert.background 'white'
      convert.gravity 'center'
      convert.extent '1240x1754'
      convert << output_path
    end

    raise "A4 PDF not generated" unless File.exist?(output_path)

    output_path
  end


end
