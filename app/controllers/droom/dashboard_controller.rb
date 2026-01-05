module Droom
  class DashboardController < Droom::DroomController
    respond_to :html, :js
    skip_authorization_check

    before_action :prepare_summary, only: [:index]

    def index
      authorize! :read, :dashboard
      @timezone_feature = FeatureFlag.enabled?('time-zone-feature', current_user)
      render layout: Droom.centered_layout.to_s
    end

    private

    def prepare_summary
      grants = Grant.where(show: 1)
      @total_grants = grants.total_count

      awards = Award.where(show: 1)
      @total_awards = awards.total_count

      scholars = PersonPage.where(metadata: true)
      @total_scholars = scholars.total_count

      latest_fss_applications = Application.where(latest_fss: true)
      @total_fss_applications = latest_fss_applications.total_count
    end
  end
end
