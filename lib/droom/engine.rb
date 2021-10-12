require 'rubygems'
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
  class Engine < ::Rails::Engine
    isolate_namespace Droom

    initializer "droom.integration" do
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
