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
    ['thumbnail', 'pdf'].each do |mode|
      meeting_text = generate_meeting_text
      pdf = prepare_prawn(mode, meeting_text)

      tempfile = create_tempfile(pdf)
      generate_thumbnails(tempfile.path, mode)
    end
  end

  def generate_thumbnails(file_path, mode=nil)
    return unless file_path.present?

    total_pages = get_total_pages(file_path)
    process_pdf_pages(file_path, total_pages, mode)
  end

  private

  def generate_meeting_text
    datetime_str = "#{self.start.strftime('%A %d %B %Y')} at #{self.start.strftime('%I:%M%p')}"
    "#{meeting_texts[self.event_type_id]} #{datetime_str}"
  end

  def meeting_texts
    {
      1 => "A Trustees’ Meeting is to be held on",
      2 => "A meeting of the NCF Nomination Committee is to be held on",
      3 => "An Investment Committee Meeting is to be held on",
      4 => "An Audit Committee Meeting is to be held on",
      5 => "A Governors’ Meeting is to be held on",
      6 => "A meeting of the CF Nomination & Remuneration Committee is to be held on",
      7 => "A meeting of the Academic Assessment Working Group is to be held on"
    }
  end

  def prepare_prawn(mode, meeting_text)
    pdf = Prawn::Document.new(page_size: "A4", margin: 0)
    set_background_color(pdf)
    add_logo(pdf)
    add_text(pdf, mode, meeting_text)
    pdf
  end

  def set_background_color(pdf)
    bg_color = ["1", "2", "3", "6"].include?(self.event_type_id.to_s) ? "EE3A43" : "56C1FF"
    pdf.fill_color = bg_color
    pdf.fill_rectangle [pdf.bounds.left, pdf.bounds.top], pdf.bounds.width, pdf.bounds.height
  end

  def add_logo(pdf)
    logo_path = Rails.root.join("app/assets/images/croucher_white_logo.png")
    pdf.image(logo_path, at: [45, 790], height: 110) if File.exist?(logo_path)
  end

  def add_text(pdf, mode, meeting_text)
    pdf.fill_color "FFFFFF"
    set_font(pdf, mode)

    pdf.text_box meeting_text, at: [40, 630], size: 24, width: 450, align: :left

    pdf.stroke_color "FFFFFF"

    add_links(pdf)
  end

  def set_font(pdf, mode)
    if mode == 'thumbnail'
      pdf.font("Helvetica")
    else
      font_path = Rails.root.join("app/assets/stylesheets/ui-library/fonts/MarrSans-Regular.otf")
      pdf.font_families["MarrSans"] = { normal: font_path.to_s }
      pdf.font("MarrSans")
    end
  end

  def add_links(pdf)
    pdf.text_box "To join the meeting click <u><link href='https://#{self.video_conference_link}' target='_blank'>here</link></u>",
                 at: [40, 480], size: 24, width: 450, align: :left, inline_format: true

    pdf.text_box "To go to the dataroom click <u><link href='https://data.croucher.org.hk' target='_blank'>here</link></u>",
                 at: [40, 430], size: 24, width: 450, align: :left, inline_format: true
  end

  def create_tempfile(pdf)
    tempfile = Tempfile.new(["cover_#{self.id}", ".pdf"])
    tempfile.binmode
    tempfile.write(pdf.render)
    tempfile.rewind
    tempfile
  end

  def get_total_pages(pdf_tempfile)
    CombinePDF.load(pdf_tempfile).pages.count
  rescue => e
    Rails.logger.error("Error reading PDF page count: #{e.message}")
    1
  end

  def process_pdf_pages(file_path, total_pages, mode)
    (0...total_pages).each do |page_number|
      generate_page(file_path, page_number, mode)
    end
  rescue => e
    Rails.logger.error("PDF processing failed: #{e.message}")
  ensure
    Rails.logger.info("PDF processing complete: #{total_pages} pages")
  end

  def generate_page(file_path, page_number, mode)
    if mode == 'thumbnail' || mode.nil?
      thumbnail_path = convert_page_to_image(file_path, page_number)
      attach_thumbnail(thumbnail_path, page_number)
      cleanup_file(thumbnail_path)
    end

    if mode == 'pdf' || mode.nil?
      pdf_page_path = extract_single_pdf_page(file_path, page_number)
      attach_pdf_page(pdf_page_path, page_number)
      cleanup_file(pdf_page_path)
    end
  end

  def convert_page_to_image(pdf_tempfile, page_number)
    output = Tempfile.new(["thumb_#{page_number}", ".jpg"])
    output.close

    MiniMagick::Tool::Magick.new do |magick|
      magick.density '300'
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
