require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::FoldersController, type: :controller do
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
    it "allows an administrator to access a private folder" do
      viewer.update!(admin: true)
      folder = FactoryGirl.create(:folder, private: true)

      get :show, params: { id: folder.id, view: "data_room" }

      expect(response).to have_http_status(:ok)
    end

    it "denies a direct ID lookup without exposing folder contents" do
      folder = FactoryGirl.create(:folder, name: "Restricted folder", data_room: true)
      child = folder.children.create!(name: "Restricted child", slug: "restricted-child")
      document = FactoryGirl.create(:document, folder: folder, name: "restricted-file.pdf")

      get :show, params: { id: folder.id, view: "data_room" }

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include(folder.name)
      expect(response.body).not_to include(child.name)
      expect(response.body).not_to include(document.name)
    end

    it "allows a recipient to access a descendant of a shared folder" do
      shared_folder = FactoryGirl.create(:folder)
      descendant = shared_folder.children.create!(name: "Shared descendant", slug: "shared-descendant")
      Droom::Share.create!(shareable: shared_folder, shared_with: viewer, shared_by: FactoryGirl.create(:user))

      get :show, params: { id: descendant.id, view: "data_room" }

      expect(response).to have_http_status(:ok)
    end

    it "denies a private folder to a non-admin recipient" do
      folder = FactoryGirl.create(:folder, private: true)
      Droom::Share.create!(shareable: folder, shared_with: viewer, shared_by: FactoryGirl.create(:user))

      get :show, params: { id: folder.id, view: "data_room" }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET #child_folders" do
    it "does not enumerate children of an inaccessible parent" do
      folder = FactoryGirl.create(:folder)
      child = folder.children.create!(name: "Hidden child", slug: "hidden-child")

      get :child_folders, params: { target_parent_id: folder.id }, format: :json

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include(child.name)
    end
  end
end
