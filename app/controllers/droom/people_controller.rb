module Droom
  class PeopleController < Droom::EngineController
    respond_to :json, :html, :js
    before_filter :authenticate_user!  
    
    def index

    end
 
  end
end