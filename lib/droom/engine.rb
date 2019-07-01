require 'rubygems'
require 'paperclip'
require 'devise'
require 'devise-security'
require 'devise_zxcvbn'
require 'cancan'
require 'kaminari'
require 'icalendar'
require 'haml'
require 'mail_form'

module Droom
  class Engine < ::Rails::Engine
    isolate_namespace Droom

    initializer "droom.integration" do
      Devise.parent_controller = "Droom::ApplicationController"
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
