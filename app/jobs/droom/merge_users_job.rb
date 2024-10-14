module Droom
  class MergeUsersJob < ActiveJob::Base

    def perform(keep_id, merge_id)
      kept_user = Droom::User.find_by(id: keep_id)
      merged_user = Droom::User.find_by(id: merge_id)
      if kept_user && merged_user
        Searchkick.callbacks(false) do
          kept_user.subsume!(merged_user)
          kept_user.subsume_remote_resources(merged_user)
        end
        sleep 5
        # merged_user.destroy
        merged_user.update(deleted_at: Time.current)
        kept_user.reindex
      end
    end

  end
end
