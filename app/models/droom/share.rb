module Droom
  class Share < Droom::DroomRecord
    belongs_to :shareable, :polymorphic => true
    belongs_to :shared_with, :class_name => "Droom::User"
    belongs_to :shared_by, :class_name => "Droom::User"

    validates :shared_with_id, uniqueness: { scope: [:shareable_type, :shareable_id] }

    before_create :generate_token

    scope :for_user, -> user {
      where(["shared_with_id = ?", user.id])
    }

    scope :by_user, -> user {
      where(["shared_by_id = ?", user.id])
    }

    scope :of_type, -> type {
      where(["shareable_type = ?", type])
    }

    private

    def generate_token
      self.token = SecureRandom.urlsafe_base64(32)
    end
  end
end
