module Droom
  class DashboardController < Droom::DroomController
    respond_to :html, :js
    skip_authorization_check
    before_action :redirect_to_er_hub

    def index
      authorize! :read, :dashboard
      render layout: Droom.dashboard_layout.to_s
    end

    private

    # force redirect to ER hub
    def redirect_to_er_hub
      return redirect_to main_app.emergency_responses_url if current_user.guest? || current_user.intermediary?
    end

  end
end
