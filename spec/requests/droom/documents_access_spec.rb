require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::DocumentsController, type: :controller do
  routes { Droom::Engine.routes }

  let(:viewer) { FactoryGirl.create(:user) }

  before do
    controller.stub(:current_user).and_return(viewer)
    controller.stub(:user_signed_in?).and_return(true)
    controller.stub(:authenticate_user!).and_return(true)
    controller.stub(:check_data_room_permission)
    controller.stub(:check_user_is_confirmed)
    controller.stub(:check_user_setup)
    controller.stub(:check_user_has_organisation)
  end

  describe "GET #show" do
    it "allows an administrator to download a private document" do
      viewer.update!(admin: true)
      folder = FactoryGirl.create(:folder, private: true)
      document = FactoryGirl.create(:document, folder: folder)
      attach_file(document)

      get :show, params: { id: document.id }

      expect(response).to redirect_to(document.file.url)
    end

    it "does not redirect to an attachment URL for an unauthorized document ID" do
      folder = FactoryGirl.create(:folder, data_room: true)
      document = FactoryGirl.create(:document, folder: folder, name: "restricted-file.pdf")
      attach_file(document)

      get :show, params: { id: document.id }

      expect(response).to have_http_status(:not_found)
      expect(response.headers["Location"]).to be_nil
      expect(response.body).not_to include(document.name)
      expect(response.body).not_to include(document.file.url)
    end

    it "allows a document in a descendant of a shared folder" do
      shared_folder = FactoryGirl.create(:folder)
      descendant = shared_folder.children.create!(name: "Shared descendant", slug: "document-shared-descendant")
      document = FactoryGirl.create(:document, folder: descendant)
      attach_file(document)
      Droom::Share.create!(shareable: shared_folder, shared_with: viewer, shared_by: FactoryGirl.create(:user))

      get :show, params: { id: document.id }

      expect(response).to redirect_to(document.file.url)
    end

    it "denies a directly shared document in an inaccessible parent folder" do
      folder = FactoryGirl.create(:folder, private: true)
      document = FactoryGirl.create(:document, folder: folder, name: "private-descendant.pdf")
      attach_file(document)
      Droom::Share.create!(shareable: document, shared_with: viewer, shared_by: FactoryGirl.create(:user))

      get :show, params: { id: document.id }

      expect(response).to have_http_status(:not_found)
      expect(response.headers["Location"]).to be_nil
      expect(response.body).not_to include(document.name)
    end
  end

  private

  def attach_file(document)
    document.file.attach(
      io: StringIO.new("security test file"),
      filename: "security-test.txt",
      content_type: "text/plain"
    )
  end
end
