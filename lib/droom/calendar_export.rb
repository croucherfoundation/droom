module Droom
  module CalendarExport
    def icalendar_event(user: nil)
      event = Icalendar::Event.new
      event.uid = uuid
      event.summary = name
      description = plain_description(user: user)
      event.description = description if description.present?
      if all_day? && start?
        event.dtstart = Icalendar::Values::Date.new(start_date)
        exclusive_end = end_date ? end_date + 1.day : (finish_date || start_date + 1.day)
        event.dtend = Icalendar::Values::Date.new(exclusive_end)
      else
        event.dtstart = start if start?
        event.dtend = finish if finish?
      end
      if updated_at
        event.dtstamp = Icalendar::Values::DateTime.new(updated_at.utc, "tzid" => "UTC")
        event.last_modified = Icalendar::Values::DateTime.new(updated_at.utc, "tzid" => "UTC")
        event.sequence = calendar_sequence
      end
      event.url = url_with_protocol if url?
      event.attendee = invitations.accepted.map { |inv| "mailto:#{inv.user.email}" } if invitations.accepted.any?
      event.location = venue.name if venue
      event
    end
  end
end
