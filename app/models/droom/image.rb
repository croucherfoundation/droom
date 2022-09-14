require "open-uri"

module Droom
  class Image < Droom::DroomRecord
    include ActiveStorageSupport::SupportForBase64

    belongs_to :user
    belongs_to :organisation
    attr_accessor :remote_url

    has_one_base64_attached :file

    before_validation :get_organisation
    before_validation :read_remote_url

    def sizes
      {
        icon:     { resize: "96x64" },
        half:     { resize: "480x320" },
        full:     { resize: "960x640" },
        hero:     { resize: "1600x1600" },
        original: { resize: "1920x1080" }
      }
    end

    def url(size=:original)
      if file.attached?
        file.variant(self.sizes[size]).processed.url
      else
        ""
      end
    end

    def file_url=(address)
      if address.present?
        begin
          self.file = URI(address)
        rescue OpenURI::HTTPError => e
          Rails.logger.warn "Cannot read image url #{address} because: #{e}. Skipping."
        end
      end
    end

    def file_name=(name)
      self.file.filename = name
    end

    def file_data=(data)
      self.file.attach(data: data)
    end

    protected

    def get_organisation
      self.organisation ||= user.organisation if user
    end

    def read_remote_url
      if remote_url
        self.file = open(remote_url)
        self.file_name = File.basename(remote_url)
      end
    end

  end
end
