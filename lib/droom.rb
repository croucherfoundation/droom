require 'dav4rack'
require 'dav4rack/resources/file_resource'
require "droom/monkeys"
require "droom/helpers"
require "droom/renderers"
require "droom/engine"
require "droom/validators"
require "droom/dav_resource"
require "droom/searchability"
require "droom/taggability"
require "droom/folders"
require "droom/preferences"
require "snail"

module Droom
  # Droom configuration is handled by accessors on the Droom base module.
  
  mattr_accessor :root_path,
                 :layout,
                 :email_layout,
                 :email_host,
                 :email_from,
                 :email_return_path,
                 :main_dashboard_modules,
                 :margin_dashboard_modules,
                 :dav_root,
                 :dav_subdomain,
                 :use_forenames,
                 :show_venue_map,
                 :default_document_private,
                 :default_event_private,
                 :dropbox_app_key,
                 :dropbox_app_secret
  
  class DroomError < StandardError; end
  class PermissionDenied < DroomError; end
  
  class << self
    def layout
      @@layout ||= "droom/application"
    end
    
    def email_host
      @@email_host ||= "please-change-email-host-in-droom-initializer.example.com"
    end

    def email_layout
      @@email_layout ||= "droom/email"
    end

    def email_from
      @@email_from ||= "please-change-email-from-in-droom-initializer@example.com"
    end
    
    def email_return_path
      @@email_return_path ||= email_from
    end

    def root_path
      @@root_path ||= "dashboard#index"
    end

    def home_country
      Snail.home_country = @@home_country ||= 'gb'
    end

    def main_dashboard_modules
      @@main_dashboard_modules ||= %w{my_future_events my_folders}
    end

    def margin_dashboard_modules
      @@margin_dashboard_modules ||= []
    end
    
    # base path of DAV directory tree, relative to rails root.
    def dav_root
      @@dav_root ||= "webdav"
    end
    
    # subdomain constraint applied when routing to dav.
    def dav_subdomain
      @@dav_subdomain ||= /dav/
    end

    def use_forenamnes
      !!@@use_forenames
    end

    def show_venue_map
      !!@@show_venue_map
    end

    def suggestible_classes=(hash)
      @@suggestible_classes = hash
    end

    def suggestible_classes
      @@suggestible_classes ||= {
        "event" => "Droom::Event", 
        "person" => "Droom::Person", 
        "document" => "Droom::Document",
        "group" => "Droom::Group",
        "venue" => "Droom::Venue"
      }
    end

    def searchable_classes
      @@searchable_classes ||= {
        "event" => "Droom::Event",
        "document" => "Droom::Document",
        "group" => "Droom::Group",
        "venue" => "Droom::Venue"
      }
    end

    def add_suggestible_class(label, klass=nil)
      klass ||= label.titlecase
      suggestible_classes[label] = klass.to_s
    end
    
    # Droom's preferences are arbitrary and open-ended. You can ask for any preference key: if it 
    # doesn't exist you just get back the default value, or nil if there isn't one. This is where you
    # set the defaults.
    #
    def user_defaults
      @@defaults ||= {
        :email =>  {
          :enabled? => true,
          :digest? => false,
          :invitations? => false
        },
        :dropbox => {
          :everything? => false,
          :events? => true,
          :topics? => false
        },
        :dav => {
          :everything? => false,
          :events? => false,
          :topics? => false
        }
      }
    end
    
    # Here we are overriding droom settings in a host app initializer.
    # key should be colon-separated and string-like:
    #
    #   Droom.set_default('email:digest', true)
    #
    # Hash#deep_set is a setter that can take compound keys and set nested values. It's defined in lib/monkeys.rb.
    #
    def set_user_default(key, value)
      defaults.set(key, value)
    end
    
    def user_default(key)
      defaults.get(key)
    end
  end
end
