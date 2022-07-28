module Droom
  class GroupInvitationJob < ActiveJob::Base
    queue_as :default

    def perform(group_id, event_id)
      group = Droom::Group.find(group_id)
      event = Droom::Event.find(event_id)
      group.users.find_in_batches(batch_size: 50).each do |users|
        users.each do |user|
          Droom::GroupInvitationMailer.send_invitation(user, event).deliver
        end
      end
    end
  end
end
