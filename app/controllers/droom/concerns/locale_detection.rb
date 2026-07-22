module Droom::Concerns
  module LocaleDetection
    extend ActiveSupport::Concern

    private

    def check_locale
      raise Droom::NoChineseContent if params[:locale] == 'hk'
    end

    def set_locale
      I18n.locale = current_locale
    end

    def current_locale
      params[:locale] || default_locale
    end

    def default_locale
      I18n.default_locale
    end
  end
end
