module Droom::Concerns
  module LocaleDetection
    extend ActiveSupport::Concern

    included do
      before_action :set_locale
    end

    private

    def set_locale
      I18n.locale = current_locale
    end

    # Backend (server-rendered) pages have no Chinese translations, so any
    # main-site request explicitly asking for a Chinese locale via `locale`
    # is diverted to a holding page. The API skips this check and serves
    # Chinese normally.
    def check_locale
      raise Droom::NoChineseContent if param_requests_chinese? && !api_controller?
    end

    def current_locale
      candidate = requested_locale
      supported_locales.include?(candidate) ? candidate : default_locale
    end

    def requested_locale
      (param_locale || user_preferred_locale || session_locale || api_browser_locale).to_s
    end

    def param_locale
      params[:locale].presence
    end

    def user_preferred_locale
      return nil unless user_signed_in?
      return nil unless current_user.respond_to?(:locale)

      current_user.locale.presence
    end

    def session_locale
      session[:locale].presence if respond_to?(:session) && session
    end

    # `Accept-Language` is used only by API requests.
    def api_browser_locale
      return nil unless api_controller?

      accept_language = request.env['HTTP_ACCEPT_LANGUAGE']
      return nil unless accept_language

      preferred = accept_language.scan(/[a-z]{2}/i).first&.downcase
      preferred if supported_locales.include?(preferred)
    end

    def param_requests_chinese?
      param_locale.to_s.start_with?('zh')
    end

    def default_locale
      I18n.default_locale.to_s
    end

    def supported_locales
      %w[en zh]
    end

    def chinese_locale?
      current_locale.to_s.start_with?('zh')
    end
  end
end
