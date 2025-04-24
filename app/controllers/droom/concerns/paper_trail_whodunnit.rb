module Droom::Concerns::PaperTrailWhodunnit
  # This module is included in the Droom::DroomController
  # and is used to set the PaperTrail whodunnit for auditing
  # purposes. It ensures that the current user is set as the
  # whodunnit when creating or updating records.
  extend ActiveSupport::Concern

  included do
    before_action :set_paper_trail_whodunnit
    before_action :set_paper_trail_info
  end

  def set_paper_trail_whodunnit
    PaperTrail.request.whodunnit = user_signed_in? ? current_user.uid : nil
  end

  def set_paper_trail_info
    PaperTrail.request.controller_info = {
      ip: request.remote_ip,
      user_agent: request.user_agent
  }
  end
end