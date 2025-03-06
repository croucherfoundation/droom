require "prawn"

Prawn::Document.generate("compile_pdf.pdf") do
  fill_color "87CEFA" 
  fill_rectangle [bounds.left, bounds.top], bounds.width, bounds.height

  logo_path = Rails.root.join("app/assets/images/croucher_logo.png")
  image logo_path, at: [50, 700], height: 50

  fill_color "FFFFFF"
  font "Helvetica"
  text_box "A Governors’ Meeting is to be held on Tuesday 22 October at 3:30pm",
           at: [150, 650], size: 24, width: 400, align: :left
end
