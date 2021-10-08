class Droom::EventSerializer
  include JSONAPI::Serializer

  attributes :id,
             :event_type_id,
             :start,
             :finish,
             :name,
             :slug,
             :description,
             :url,
             :venue_id,
             :event_set_id,
             :created_by_id,
             :uuid,
             :all_day,
             :master_id,
             :calendar_id,
             :confidential,
             :timezone,
             :private,
             :public,
             :indexed_at,
             :datestring,
             :created_at,
             :updated_at

  attribute :datestring do |object|
    I18n.l object.start, :format => :natural_with_date
  end

end
