module Droom
  class DroomController < ActionController::Base
    include Droom::Concerns::ControllerHelpers
    helper Droom::DroomHelper
    helper ApplicationHelper

    before_action :set_timezone

    protected

    def set_timezone
      if user_signed_in? && !api_controller?
        # FeatureFlag.upsert_flags

        if current_user.timezone.present?
          cookies[:timezone] = current_user.timezone
        else
          cookies[:timezone] = "NoTimezone"
        end

      end
    end
    
    def api_controller?
      false
    end

  end
end
