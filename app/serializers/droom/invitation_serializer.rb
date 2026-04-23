class Droom::InvitationSerializer < ActiveModel::Serializer
  attributes :id,
             :event_id,
             :user_id,
             :user_uid
  
  def user_uid
    object.user&.uid
  end

  def event_id
    object.event.uuid
  end
end
