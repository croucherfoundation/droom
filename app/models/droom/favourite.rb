module Droom
  class Favourite < Droom::DroomRecord
    belongs_to :user
    belongs_to :favouritable, :polymorphic => true

    validates :user_id, uniqueness: { scope: [:favouritable_type, :favouritable_id] }

    scope :for_user, -> user {
      where(["user_id = ?", user.id])
    }

    scope :of_type, -> type {
      where(["favouritable_type = ?", type])
    }
  end
end
