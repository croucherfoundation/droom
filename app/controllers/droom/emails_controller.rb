# Address book data is always nested. Here we are only providing add-item form partials through #new.
#
module Droom
  class EmailsController < Droom::DroomController
    layout false
    load_resource :user, class: "Droom::User"
    load_and_authorize_resource through: :user

    def new
      if params[:type].present? && params[:type] == 'scholar'
        render :partial => 'shared/account_settings/emails/fields'
      end
    end
  end
end