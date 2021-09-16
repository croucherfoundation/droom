require "open-uri"

module Droom
  class Image < Droom::DroomRecord
    belongs_to :user
    belongs_to :organisation
    attr_accessor :remote_url

    has_one_attached :file

    before_validation :get_organisation
    before_validation :read_remote_url

    def url(style=:original, decache=true)
      if file?
        url = file.url(style, decache)
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
          Rails.logger.warn "Cannot read image url #{address} because: #{e}. Skipping."
        end
      end
    end

    def file_name=(name)
      self.file_file_name = name
    end

    def file_data=(data)
      self.file = data
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
