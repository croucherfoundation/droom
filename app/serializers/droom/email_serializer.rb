class Droom::EmailSerializer < ActiveModel::Serializer
  attributes :id,
             :user_id,
             :user_uid,
             :email,
             :default,
             :address_type_id,
             :address_type,
             :ses_status,
             :pending_email,
             :email_verification_token,
             :email_verification_sent_at

  belongs_to :user

  def address_type
    object&.address_type&.name
  end

  def user_uid
    object&.user&.uid
  end
end
