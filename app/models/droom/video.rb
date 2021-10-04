module Droom
  class Video < Droom::DroomRecord
    belongs_to :user
    belongs_to :organisation

    has_one_attached :file

    before_validation :get_organisation
    before_validation :get_metadata

    def url(style=:original)
      if file.attached?
        url = file.url
        url.sub(/^\//, "#{Settings.protocol}://#{Settings.host}/")
      else
        ""
      end
    end

    def file_url=(address)
      if address.present?
        begin
          self.file = URI(address)
        rescue OpenURI::HTTPError => e
          Rails.logger.warn "Cannot read video url #{address} because: #{e}. Skipping."
        end
      end
    end

    def file_name=(name)
      self.file_file_name = name
    end

    protected

    def get_metadata
      if remote_url?
        if video = VideoInfo.new(remote_url)
          self.provider = video.provider
          self.thumbnail_large = video.thumbnail_large
          self.thumbnail_medium = video.thumbnail_medium
          self.thumbnail_small = video.thumbnail_small
          self.width = video.width
          self.height = video.height
          self.duration = video.duration
          self.embed_code = video.embed_code
        end
      else
        self.provider = 'local'
        self.thumbnail_large = nil
        self.thumbnail_medium = nil
        self.thumbnail_small = nil
        self.width = nil
        self.height = nil
        self.duration = nil
      end
    end

    def get_organisation
      self.organisation ||= user.organisation if user
    end

  end
end
