module Droom
  class Config
    attr_accessor :root_path,
                  :home_url,
                  :cors_domains,
                  :suggestible_classes,
                  :searchable_classes,
                  :api_local,
                  :mailer,
                  :layout,
                  :dashboard_layout,
                  :page_layout,
                  :devise_layout,
                  :email_layout,
                  :email_host,
                  :email_from,
                  :email_from_name,
                  :email_return_path,
                  :main_dashboard_modules,
                  :margin_dashboard_modules,
                  :panels,
                  :use_noticeboard,
                  :scrap_types,
                  :default_scrap_type,
                  :use_chinese_names,
                  :use_biogs,
                  :use_separate_mobile_number,
                  :use_titles,
                  :use_honours,
                  :registerable,
                  :use_organisations,
                  :require_organisation,
                  :enable_mailing_lists,
                  :mailman_table_name,
                  :mailing_lists_active_by_default,
                  :mailing_lists_digest_by_default,
                  :yt_client,
                  :show_venue_map,
                  :dropbox_enabled,
                  :dropbox_app_key,
                  :dropbox_app_secret,
                  :dropbox_app_name,
                  :user_defaults,
                  :people_sort,
                  :required_calendar_names,
                  :stream_shared,
                  :aws_bucket_name,
                  :all_events_public,
                  :all_documents_public,
                  :password_pattern,
                  :separate_calendars,
                  :second_time_zone,
                  :require_login_permission,
                  :require_internal_organisation,
                  :users_can_invite,
                  :default_permissions,
                  :mc_api_key,
                  :mc_news_template,
                  :mc_news_list,
                  :session_timeout,
                  :enable_pubsub

    def home_url
      @home_url ||= "http://example.com"
    end
 
    def cors_domains
      @cors_domains || []
    end

    def api_local?
      !!@api_local
    end

    def mailer
      @mailer || Droom::Mailer
    end
 
    def layout
      @layout ||= "application"
    end
 
    def dashboard_layout
      @dashboard_layout ||= "application"
    end
 
    def page_layout
      @page_layout ||= "page"
    end
 
    def devise_layout
      @devise_layout ||= "application"
    end
 
    def email_host
      @email_host ||= "please-change-email-host-in-droom-initializer.example.com"
    end
 
    def email_layout
      @email_layout ||= "email"
    end
 
    def email_from
      @email_from ||= "please-change-email_from-in-droom-initializer@example.com"
    end
 
    def email_from_name
      @email_from ||= "Please Set Email-From Name In Droom Initializer"
    end
 
    def email_return_path
      @email_return_path ||= email_from
    end
 
    def people_sort
      @people_sort ||= "position ASC"
    end
 
    def sign_out_path
      @sign_out_path ||= "/users/sign_out"
    end
 
    def root_path
      @root_path ||= "dashboard#index"
    end
 
    def main_dashboard_modules
      @main_dashboard_modules ||= %w{my_future_events my_folders}
    end
 
    def margin_dashboard_modules
      @margin_dashboard_modules ||= %w{quicksearch stream}
    end
 
    def panels
      @panels ||= %w{configuration search admin}
    end
 
    def use_noticeboard?
      !!@use_noticeboard
    end
 
    def scrap_types
      @scrap_types ||= %w{image text quote link event document}
    end
 
    def default_scrap_type
      @default_scrap_type ||= 'text'
    end
 
    def use_chinese_names?
      !!@use_chinese_names
    end
 
    def use_titles?
      !!@use_titles
    end
 
    def use_honours?
      !!@use_honours
    end
 
    def use_biogs?
      !!@use_biogs
    end
 
    def registerable=(value)
      @registerable = value
    end
 
    def registerable?
      !!@registerable
    end
 
    def use_organisations?
      !!@use_organisations
    end
 
    def require_organisation?
      !!@require_organisation
    end
 
    def stream_shared?
      !!@stream_shared
    end
 
    def use_separate_mobile_number?
      !!@use_separate_mobile_number
    end
 
    def enable_mailing_lists?
      !!@enable_mailing_lists
    end
 
    def calendar_closed?
      !!@calendar_closed
    end
 
    def all_events_public?
      !!@all_events_public
    end
 
    def all_documents_public?
      !!@all_documents_public
    end
 
    def dropbox_enabled?
      !!@dropbox_enabled
    end
 
    def dropbox_app_name
      @dropbox_app_name ||= 'droom'
    end
 
    def mailman_table_name
      @mailman_table_name ||= 'mailman_mysql'
    end
 
    def mailing_lists_active_by_default?
      !!@mailing_lists_active_by_default
    end
 
    def mailing_lists_digest_by_default?
      !!@mailing_lists_digest_by_default
    end
 
    def show_venue_map?
      !!@show_venue_map
    end
 
    def suggestible_classes
      @suggestible_classes ||= {
        "event" => "Droom::Event", 
        "user" => "Droom::User", 
        "document" => "Droom::Document",
        "group" => "Droom::Group",
        "venue" => "Droom::Venue"
      }
    end
 
    def add_suggestible_class(label, klass=nil)
      klass ||= label.camelize
      suggestible_classes[label] = klass.to_s
    end
 
    def yt_client
      @yt_client ||= YouTubeIt::Client.new(:dev_key => "AI39si473p0K4e6id0ZrM1vniyk8pdbqr67hH39hyFjW_JQoLg9xi6BecWFtraoPMCeYQmRgIc_XudGKVU8tmeQF8VHwjOUg8Q")
    end
 
    def aws_bucket_name
      @aws_bucket_name ||= nil
    end
 
    def aws_bucket
      @aws_bucket ||= Fog::Storage.new(Droom::Engine.config.paperclip_defaults[:fog_credentials]).directories.get(@aws_bucket_name)
    end
 
    def required_calendar_names
      @required_calendar_names ||= %w{main stream}
    end
 
    def separate_calendars?
      !!@separate_calendars
    end
 
    def second_time_zone?
      !!@second_time_zone
    end
 
    def password_pattern
      @password_pattern ||= ".{6,}"
    end
 
    def require_login_permission?
      !!@require_login_permission
    end
 
    def require_internal_organisation?
      !!@require_internal_organisation
    end
 
    def users_can_invite?
      !!@users_can_invite
    end
 
    def default_permissions
      @default_permissions ||= %w{droom.login droom.calendar droom.directory droom.attach droom.library}
    end
 
    def session_timeout
      @@session_timeout ||= 1.minutes
    end
    
    def enable_pubsub?
      !!@enable_pubsub
    end
 
 
    ## Mailchimp integration
    # supports list management and eventually, message composition.
    #
    def mc_api_key
      @mc_api_key
    end
 
    def mc_news_template
      @mc_news_template
    end
 
    def mc_news_list
      @mc_news_list
    end
  
    def mailchimp_configured?
      mc_api_key.present? && mc_news_list.present? && mc_news_list.present?
    end


    # Droom's preferences are arbitrary and open-ended. You can ask for any preference key: if it
    # doesn't exist you just get back the default value, or nil if there isn't one. This is where you
    # set the defaults.
    #
    def user_defaults
      @user_defaults ||= Droom::LazyHash.new({})
    end

    def set_user_defaults(defaults={})
      @user_defaults = Droom::LazyHash.new(defaults)
    end
 
    # We are probably overriding droom default settings in a host app initializer to create local default settings.
    # key should be dot-separated and string-like:
    #
    #   config.set_user_default('email.digest', true)
    #
    def set_user_default(key, value)
      user_defaults.set(key, value)
    end
 
    def user_default(key)
      user_defaults.get(key)
    end
  end
end