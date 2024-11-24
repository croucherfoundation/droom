require 'erb'
require 'tempfile'
require 'mini_magick'

module Droom::Concerns::PngConvert
  extend ActiveSupport::Concern
  COLORS = %w(#531A04 #C82F32 #CDC405 #EDA306 #93B4D7).freeze
  def convert_to_png(name)
    
    @background = COLORS.sample
    @letters = name.split.take(2).map { |word| word[0].upcase }.join

    svg_content = svg_template
    svg_content = ERB.new(svg_content).result(binding).strip

    output_path = Rails.root.join('tmp', "#{convert_to_underscored(name)}.png")
    convert_svg_to_png(svg_content, output_path)
    output_path
  end

  def svg_template
    <<-SVG
      <?xml version="1.0" encoding="UTF-8"?>
      <svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="500" height="500" viewBox="0 0 60 60">
        <style>
          @font-face {
            font-family: 'MarrSans';
            src: url('https://front.croucherscienceweek.hk/MarrSans-Bold.otf') format('opentype');
            font-weight: normal;
            font-display: swap;
            -webkit-font-smoothing: antialiased;
          }
          text {
            font-family: "MarrSans", Arial, sans-serif;
          }
        </style>
        <!-- Background Rectangle -->
        <rect width="100%" height="100%" fill="<%= @background %>"/>
        
        <!-- Centered Text with Equal Margins -->
        <text fill="#fff" font-size="30" font-weight="500" x="50%" y="50%" dx="0" dy=".25em" text-anchor="middle" dominant-baseline="middle">
          <%= @letters %>
        </text>
      </svg>
    SVG
  end

  def convert_svg_to_png(svg_content, output_path, resolution = 600)
    Tempfile.create(['temp_svg', '.svg']) do |svg_file|
      svg_file.write(svg_content)
      svg_file.flush

      image = MiniMagick::Image.open(svg_file.path)
      image.format 'png'
      image.density resolution # High-quality conversion
      image.resize '500x500'
      image.write output_path
    end
  end

  def convert_to_underscored(name)
    name.strip.gsub(/\s+/, '_').downcase
  end

  def attach_initials_image(user)
    return if user.informal_name.blank?

    begin
      initials_image_path = convert_to_png(user.informal_name)
      user.image.attach(io: File.open(initials_image_path), filename: File.basename(initials_image_path))
      user.update(show_initial_image: true)
      puts "Initials image attached for user #{user.informal_name}"
    rescue => e
      puts "Failed to attach initials image for user #{user.name}: #{e.message}"
    end
  end

end