module Droom
  class DroomController < ActionController::Base
    include BetterContentSecurityPolicy::HasContentSecurityPolicy
    include Droom::Concerns::ControllerHelpers
    after_action :set_content_security_policy_header
    helper Droom::DroomHelper
    helper ApplicationHelper

    def configure_content_security_policy
      content_security_policy.default_src :self, :https
      content_security_policy.font_src :self, :https, :data
      content_security_policy.script_src %w('self' https: 'unsafe-inline')
      content_security_policy.style_src %w('self' https: 'unsafe-inline')
      content_security_policy.img_src :self, %(https://www.google.com https://www.google-analytics.com https://hkfx.s3.ap-southeast-1.amazonaws.com)
      content_security_policy.object_src :none
      content_security_policy.worker_src :self
      content_security_policy.manifest_src :self
      content_security_policy.frame_src :self
      content_security_policy.form_action :none
      content_security_policy.frame_ancestors :none
    end

  end
end
