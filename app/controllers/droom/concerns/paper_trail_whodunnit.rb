module Droom::Concerns::PaperTrailWhodunnit
  # This module is included in the Droom::DroomController
  # and is used to set the PaperTrail whodunnit for auditing
  # purposes. It ensures that the current user is set as the
  # whodunnit when creating or updating records.
  extend ActiveSupport::Concern

  included do
    before_action :set_paper_trail_whodunnit
  end

  def set_paper_trail_whodunnit
    PaperTrail.request.whodunnit = user_signed_in? ? current_user.uid : nil
  end
end