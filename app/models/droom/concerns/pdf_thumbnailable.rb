require 'mini_magick'
require 'combine_pdf'
require 'open-uri'

module Droom::Concerns::PdfThumbnailable
  extend ActiveSupport::Concern

  included do
    has_many :thumbnails, dependent: :destroy
    has_many :single_documents, dependent: :destroy
  end

  def pdf_cover_generate
    meeting_texts = {
      1 => "A Trustees’ Meeting is to be held on",
      2 => "A meeting of the NCF Nomination Committee is to be held on",
      3 => "An Investment Committee Meeting is to be held on",
      4 => "An Audit Committee Meeting is to be held on",
      5 => "A Governors’ Meeting is to be held on",
      6 => "A meeting of the CF Nomination & Remuneration Committee is to be held on",
      7 => "A meeting of the Academic Assessment Working Group is to be held on"
    }

    datetime_str = "#{self.start.strftime('%A %d %B %Y')} at #{self.start.strftime('%I:%M%p')}"
    meeting_text = "#{meeting_texts[self.event_type_id]} #{datetime_str}"

    pdf = Prawn::Document.new(page_size: "A4", margin: 0)
    bg_color = [1, 2, 3, 6].include?(self.event_type_id) ? "EE3A43" : "56C1FF"
    pdf.fill_color = bg_color
    pdf.fill_rectangle [pdf.bounds.left, pdf.bounds.top], pdf.bounds.width, pdf.bounds.height

    logo_path = Rails.root.join("app/assets/images/croucher_white_logo.png")
    pdf.image(logo_path, at: [45, 790], height: 110) if File.exist?(logo_path)

    pdf.fill_color "FFFFFF"
    pdf.font_families.update("MarrSans" => {
      normal: Rails.root.join("app/assets/stylesheets/ui-library/fonts/MarrSans-Regular.otf")
    })
    pdf.font "MarrSans"

    pdf.text_box meeting_text,
                 at: [40, 630], size: 24, width: 450, align: :left

    pdf.stroke_color "FFFFFF"

    pdf.text_box "To join the meeting click <u><link href='https://#{self.video_conference_link}'>here</link></u>",
                 at: [40, 480], size: 24, width: 450, align: :left, inline_format: true

    pdf.text_box "To go to the dataroom click <u><link href='https://data.croucher.org.hk'>here</link></u>",
                 at: [40, 430], size: 24, width: 450, align: :left, inline_format: true

    # Save to tempfile instead of sending directly
    tempfile = Tempfile.new(["cover_#{self.id}", ".pdf"])
    tempfile.binmode
    tempfile.write(pdf.render)
    tempfile.rewind
    generate_thumbnails(tempfile.path)
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
