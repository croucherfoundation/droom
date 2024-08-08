module Droom
  class DroomController < ActionController::Base
    include Droom::Concerns::ControllerHelpers
    helper Droom::DroomHelper
    helper ApplicationHelper

    rescue_from Droom::NoChineseContent, :with => :render_holding_chinese

    before_action :set_locale
    before_action :check_locale
    before_action :set_timezone
    before_action :footer_visibility

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

    def footer_visibility
      @show_footer = controller_name == 'passwords'
    end

    def api_controller?
      false
    end

    def set_locale
      I18n.locale = params[:locale] || I18n.default_locale
    end

    def check_locale
      raise Droom::NoChineseContent if params[:locale] == 'hk'
    end

    def render_holding_chinese
      render template: "shared/holding_chinese", layout: 'application'
    end

  end
end
