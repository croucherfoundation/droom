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
      content_security_policy.script_src :self, :https
      content_security_policy.style_src :self, :https
      content_security_policy.img_src :self, :https, :data
      content_security_policy.connect_src :self
      content_security_policy.prefetch_src :self
      content_security_policy.object_src :none
    end
    
  end
end
