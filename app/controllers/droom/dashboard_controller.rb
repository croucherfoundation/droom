module Droom
  class DashboardController < Droom::DroomController
    respond_to :html, :js
    skip_authorization_check
    prepend_before_action :transfer_flash_to_request_store
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

      @total_subscribers = MailchimpSubscribersCacheService.total_count
    end

    def transfer_flash_to_request_store
      cached_data = Rails.cache.read("email_verification_cache")
      return unless cached_data.present?

      RequestStore.store[:skip_session_limitable] = true
      flash.now[:notice] = cached_data[:success_message] if cached_data[:success_message].present?
      flash.now[:alert] = cached_data[:error_message] if cached_data[:error_message].present?
      Rails.cache.delete("email_verification_cache")
    end
  end
end
