module Droom
  # Shared by upload controls and the server; never grants a new permission.
  module DocumentUpload
    def self.allowed?(ability, folder)
      return false unless folder && ability.can?(:read, folder)

      document = Droom::Document.new(folder: folder, private: folder.confidential?)
      ability.can?(:create, document) && ability.can?(:read, document)
    end
  end
end
