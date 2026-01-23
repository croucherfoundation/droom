class Droom::CalendarSerializer < ActiveModel::Serializer
  attributes :id,
             :title,
             :start,
             :end,
             :full_url

  def title
    object.name
  end

  def start
    format_datetime(object.start)
  end

  def end
    unless object.end_date.present?
      return format_datetime(object.finish) if object.finish.present?
      return format_datetime(object.start)
    end

    dt = object.end_date.to_datetime.change(
      hour: object.start_time.hour,
      min: object.start_time.min,
      sec: object.start_time.sec
    )
    format_datetime(dt)
  end

  def full_url
    Droom::Engine.routes.url_helpers.event_url(object, host: ENV['DROOM_URL'])
  end

  private

  def format_datetime(dt)
    return nil unless dt.present?
    dt.strftime("%d %B %Y, %H:%M")
  end
end
