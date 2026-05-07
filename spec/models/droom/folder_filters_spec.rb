require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::Folder do
  describe '.by_type' do
    let!(:folder) { FactoryGirl.create(:folder) }

    it 'returns all folders when type is "folders"' do
      results = Droom::Folder.by_type('folders')
      expect(results).to include(folder)
    end

    it 'returns no folders when type is "documents"' do
      results = Droom::Folder.by_type('documents')
      expect(results).to be_empty
    end

    it 'returns no folders when type is "spreadsheets"' do
      results = Droom::Folder.by_type('spreadsheets')
      expect(results).to be_empty
    end

    it 'returns no folders when type is "images"' do
      results = Droom::Folder.by_type('images')
      expect(results).to be_empty
    end
  end
end
