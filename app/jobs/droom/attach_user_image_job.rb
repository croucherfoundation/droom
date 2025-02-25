class Droom::AttachUserImageJob < ApplicationJob
  include Droom::Concerns::PngConvert

  queue_as :default

  def perform(id, model_name='Droom::User')
    record = model_name.constantize.find(id)
    attach_initials_image(record)
  end

end
