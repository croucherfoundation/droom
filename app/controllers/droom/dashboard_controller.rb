module Droom
  class DashboardController < Droom::DroomController
    respond_to :html, :js
    prepend_before_action :skip_session_limit
    skip_authorization_check


    def index
      authorize! :read, :dashboard
      @timezone_feature = FeatureFlag.enabled?('time-zone-feature', current_user)
      render layout: Droom.centered_layout.to_s
    end

  end
end
