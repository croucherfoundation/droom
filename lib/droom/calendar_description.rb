require 'cgi'
require 'nokogiri'

module Droom
  module CalendarDescription
    def description_for(user)
      return description unless user && event_type&.slug == "screening" && user.invited_to?(self)

      user.screening_calendar_descriptions.fetch(uuid)
    end

    def plain_description(user: nil)
      html = description_for(user)
      if event_type&.slug == "screening" && url?
        fragment = Nokogiri::HTML.fragment(html.to_s)
        fragment.css("a[href]").each do |link|
          next unless link["href"] == url_with_protocol && link.text.strip == "here"

          link.replace(Nokogiri::XML::Text.new("#{link.text} (#{link['href']})", fragment.document))
        end
        html = fragment.to_html
      end
      CGI.unescapeHTML(strip_tags(html).to_s)
    end
  end
end

