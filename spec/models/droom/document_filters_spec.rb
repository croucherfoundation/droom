require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::Document do
  describe '.by_type' do
    let(:folder) { FactoryGirl.create(:folder) }

    let!(:pdf_doc) do
      FactoryGirl.create(:document, name: 'report.pdf', file_content_type: 'application/pdf', folder: folder)
    end
    let!(:word_doc) do
      FactoryGirl.create(:document, name: 'letter.docx', file_content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', folder: folder)
    end
    let!(:excel_doc) do
      FactoryGirl.create(:document, name: 'budget.xlsx', file_content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', folder: folder)
    end
    let!(:csv_doc) do
      FactoryGirl.create(:document, name: 'data.csv', file_content_type: 'text/csv', folder: folder)
    end
    let!(:image_doc) do
      FactoryGirl.create(:document, name: 'photo.jpg', file_content_type: 'image/jpeg', folder: folder)
    end
    let!(:png_doc) do
      FactoryGirl.create(:document, name: 'logo.png', file_content_type: 'image/png', folder: folder)
    end

    it 'returns documents matching the "documents" type group' do
      results = Droom::Document.by_type('documents')
      expect(results).to include(pdf_doc, word_doc)
      expect(results).not_to include(excel_doc, csv_doc, image_doc, png_doc)
    end

    it 'returns documents matching the "spreadsheets" type group' do
      results = Droom::Document.by_type('spreadsheets')
      expect(results).to include(excel_doc, csv_doc)
      expect(results).not_to include(pdf_doc, word_doc, image_doc, png_doc)
    end

    it 'returns documents matching the "images" type group' do
      results = Droom::Document.by_type('images')
      expect(results).to include(image_doc, png_doc)
      expect(results).not_to include(pdf_doc, word_doc, excel_doc, csv_doc)
    end

    it 'returns no documents when type is "folders"' do
      results = Droom::Document.by_type('folders')
      expect(results).to be_empty
    end

    it 'returns all documents when type is unrecognized' do
      results = Droom::Document.by_type('unknown')
      expect(results).to include(pdf_doc, word_doc, excel_doc, csv_doc, image_doc, png_doc)
    end
  end

  describe '.modified_since' do
    let(:folder) { FactoryGirl.create(:folder) }

    let!(:recent_doc) do
      FactoryGirl.create(:document, name: 'recent.pdf', file_content_type: 'application/pdf', folder: folder).tap do |d|
        d.update_column(:updated_at, 3.days.ago)
      end
    end
    let!(:month_old_doc) do
      FactoryGirl.create(:document, name: 'month_old.pdf', file_content_type: 'application/pdf', folder: folder).tap do |d|
        d.update_column(:updated_at, 15.days.ago)
      end
    end
    let!(:old_doc) do
      FactoryGirl.create(:document, name: 'old.pdf', file_content_type: 'application/pdf', folder: folder).tap do |d|
        d.update_column(:updated_at, 400.days.ago)
      end
    end

    it 'returns documents modified in the last 7 days' do
      results = Droom::Document.modified_since('7d')
      expect(results).to include(recent_doc)
      expect(results).not_to include(month_old_doc, old_doc)
    end

    it 'returns documents modified in the last 30 days' do
      results = Droom::Document.modified_since('30d')
      expect(results).to include(recent_doc, month_old_doc)
      expect(results).not_to include(old_doc)
    end

    it 'returns documents modified in the last 365 days' do
      results = Droom::Document.modified_since('365d')
      expect(results).to include(recent_doc, month_old_doc)
      expect(results).not_to include(old_doc)
    end

    it 'returns all documents when period is unrecognized' do
      results = Droom::Document.modified_since('invalid')
      expect(results).to include(recent_doc, month_old_doc, old_doc)
    end
  end

  describe '.created_by' do
    let(:folder) { FactoryGirl.create(:folder) }
    let(:user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user) }

    let!(:user_doc) do
      FactoryGirl.create(:document, name: 'mine.pdf', file_content_type: 'application/pdf', folder: folder, created_by: user)
    end
    let!(:other_doc) do
      FactoryGirl.create(:document, name: 'theirs.pdf', file_content_type: 'application/pdf', folder: folder, created_by: other_user)
    end

    it 'returns only documents created by the specified user' do
      results = Droom::Document.created_by(user.id)
      expect(results).to include(user_doc)
      expect(results).not_to include(other_doc)
    end

    it 'returns empty when no documents belong to the user' do
      results = Droom::Document.created_by(0)
      expect(results).to be_empty
    end
  end
end
