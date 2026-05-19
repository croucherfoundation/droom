class Droom::EventSerializer < ActiveModel::Serializer
  attributes :uuid,
             :name,
             :description,
             :start,
             :finish,
             :end_date,
             :calendar_id,
             :event_type_id

end
