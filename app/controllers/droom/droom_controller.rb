module Droom
  class DroomController < ActionController::Base
    include Droom::Concerns::ControllerHelpers
    include Droom::Concerns::PaperTrailWhodunnit
    include Droom::Concerns::LocaleDetection
    include Droom::Concerns::FlashMessageHelper

    helper Droom::DroomHelper
    helper ApplicationHelper

    rescue_from Droom::NoChineseContent, :with => :render_holding_chinese

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

    def render_holding_chinese
      render template: "shared/holding_chinese", layout: 'application'
    end

    def attach_base64_image(record, attribute, base64_image)
      content_type, encoded_image = base64_image.split(',')
      decoded_image = Base64.decode64(encoded_image)
      file_extension = content_type.split('/')[1].split(';')[0]

      record.public_send(attribute).attach(
        io: StringIO.new(decoded_image),
        filename: "#{attribute}.#{file_extension}",
        content_type: content_type.split(':')[1].split(';')[0]
      )

      if record.class.name == 'Droom::User'
        record.update_column(:show_initial_image, false)
      end
    end

  end
end
