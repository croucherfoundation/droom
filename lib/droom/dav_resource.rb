# To begin with this is just a directory resource chrooted to a path
# just outside the public site. Into that we push versioned document clones
# whenever a new item becomes available.
#
# This has the great advantage of detaching DAV logic from the rest of the data room.
# If people choose to add, delete or annotate files that's ok. 
#
# Later we may move to S3-based storage, if we can give it similar simplicity.
#
module Droom
  class DavResource < DAV4Rack::FileResource

    def root
      unless @dav_root
        @dav_root = Rails.root + "webdav/#{@person.id}"
        Dir.mkdir(@dav_root) unless File.exist?(@dav_root)
      end
      @dav_root
    end
  
  private

     def authenticate(email, password)
       self.user = User.find_by_email(email)
       user.try(:valid_password?, password)
       raise ActiveRecord::RecordNotFound unless @person = user.person
       @person.refresh_personal_documents
     end

  end
end