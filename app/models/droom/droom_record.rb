module Droom
  class DroomRecord < ActiveRecord::Base
    include Droom::Concerns::ChangesNotified
    include Droom::Folders    # TODO please can we get rid of this now?
    self.abstract_class = true
    has_paper_trail ignore: [:unique_session_id, :last_request_at, :sign_in_count]
  end
end
