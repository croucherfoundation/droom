module Droom
  class ApplicationController < ActionController::Base
    include Droom::Concerns::ControllerHelpers
    helper Droom::DroomHelper
    protect_from_forgery
  end
end