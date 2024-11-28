class Droom::AttachUserImageJob < ApplicationJob
  include Droom::Concerns::PngConvert

  queue_as :default

  def perform(user_id)
    user = Droom::User.find(user_id)
    attach_initials_image(user)
  end

end
