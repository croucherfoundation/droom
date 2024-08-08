require "droom/config"
require "droom/monkeys"
require "droom/lazy_hash"
require "droom/renderers"
require "droom/engine"
require "droom/auth_cookie"
require "droom/validators"
require "droom/folders"
require "droom/scrubbers"


module Droom
  mattr_accessor :config
  @@config = Droom::Config.new

  class DroomError < StandardError; end
  class AuthRequired < DroomError; end
  class AccessDenied < DroomError; end
  class PermissionDenied < DroomError; end
  class ConfirmationRequired < DroomError; end
  class SetupRequired < DroomError; end
  class OrganisationRequired < DroomError; end
  class OrganisationApprovalRequired < DroomError; end
  class NoChineseContent < DroomError; end


  class << self
    #
    # Droom.configure do |config|
    #   config.home_url = "https://something.com"
    # end
    #
    def configure
      yield @@config
    end

    #
    # = Droom.config.home_url
    #
    def config
      @@config
    end

    # temporary delegation patch during transition to Droom.config.*
    delegate :root_path, :home_url, :cors_domains, :suggestible_classes, :searchable_classes, :mailer, :layout, :dashboard_layout, :page_layout, :devise_layout, :email_layout, :email_host, :email_from, :email_from_name, :email_return_path, :main_dashboard_modules, :margin_dashboard_modules, :panels, :use_noticeboard?, :scrap_types, :default_scrap_type, :use_chinese_names?, :use_biogs?, :use_separate_mobile_number?, :use_titles?, :use_honours?, :registerable?, :use_organisations?, :require_organisation?, :enable_mailing_lists?, :mailman_table_name, :mailing_lists_active_by_default?, :mailing_lists_digest_by_default?, :yt_client, :show_venue_map?, :dropbox_enabled?, :dropbox_app_key, :dropbox_app_secret, :dropbox_app_name, :user_defaults, :people_sort, :required_calendar_names, :stream_shared?, :aws_bucket_name, :all_events_public?, :all_documents_public?, :password_pattern, :separate_calendars, :second_time_zone, :require_login_permission?, :require_internal_organisation?, :users_can_invite?, :default_permissions, :api_local?, :mailchimp_configured?, :mc_opt_in?, :mc_api_key, :mc_news_template, :mc_news_list, to: :config

    def user_default(key)
      config.user_defaults.get(key)
    end

  end
end
