require 'rubygems'
require 'active_model_serializers'
require 'acts_as_list'
require 'acts_as_tree'
require 'cancan'
require 'chronic'
require 'date_validator'
require 'devise'
require 'devise-security'
require 'devise_zxcvbn'
require 'digest'
require 'friendly_mime'
require 'geocoder'
require 'gibbon'
require 'haml'
require 'icalendar'
require 'kaminari'
require 'mail_form'
require 'mustache'
require 'open-uri'
require 'paperclip'
require 'searchkick'
require 'tod'
require 'uuidtools'
require 'video_info'


module Droom
  class << self
    def cable
      @cable ||= ActionCable::Server::Configuration.new
    end
  end
  
  class Engine < ::Rails::Engine
    isolate_namespace Droom

    def cable
      cable ||= ActionCable::Server::Base.new(config: Droom.cable)
    end

    config.droom_cable = Droom.cable
    config.droom_cable.mount_path = "/cable"
    config.droom_cable.connection_class = -> { Droom::Connection }

    initializer "droom.integration" do
      Droom.cable.logger ||= ::Rails.logger
      Devise.parent_controller = "Droom::DroomController"
    end

    config.assets.paths << Droom::Engine.root.join('node_modules')

    ActiveSupport::Reloader.to_prepare do
      Devise::SessionsController.layout Droom.devise_layout
      Devise::RegistrationsController.layout Droom.devise_layout
      Devise::ConfirmationsController.layout Droom.devise_layout
      Devise::UnlocksController.layout Droom.devise_layout
      Devise::PasswordsController.layout Droom.devise_layout
    end

  end
end
