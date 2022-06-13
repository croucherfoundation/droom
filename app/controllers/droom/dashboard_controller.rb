module Droom
  class DashboardController < Droom::DroomController
    respond_to :html, :js
    skip_authorization_check

    def index
      authorize! :read, :dashboard
      @timezone_feature = FeatureFlag.enabled?('time-zone-feature', current_user)
      render layout: Droom.dashboard_layout.to_s
    end

  end
end
