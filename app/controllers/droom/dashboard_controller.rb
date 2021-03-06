module Droom
  class DashboardController < Droom::EngineController
    respond_to :html, :js
    layout :no_layout_if_pjax
    skip_authorization_check
    
    def index
      authorize! :read, :dashboard
      render
    end
    
  end
end