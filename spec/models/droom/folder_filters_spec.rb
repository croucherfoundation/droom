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

  describe '.created_by' do
    let(:user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user) }
    let!(:user_folder) { FactoryGirl.create(:folder, slug: 'user-folder', created_by: user) }
    let!(:other_folder) { FactoryGirl.create(:folder, slug: 'other-folder', created_by: other_user) }

    it 'returns only folders created by the specified user' do
      results = Droom::Folder.created_by(user.id)
      expect(results).to include(user_folder)
      expect(results).not_to include(other_folder)
    end

    it 'returns empty when no folders belong to the user' do
      results = Droom::Folder.created_by(0)
      expect(results).to be_empty
    end
  end
end
