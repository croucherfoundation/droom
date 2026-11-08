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

  describe "folder creation and listing" do
    render_views

    before do
      viewer.update!(admin: true)
      Droom::Folder.any_instance.stub(:reindex)
    end

    def create_folder(view:, name: "Creation regression", parent: nil, token: nil)
      post :create, params: {
        view: view,
        creation_token: token,
        folder: { name: name, slug: name.parameterize, parent_id: parent&.id }
      }, format: :html
    end

    it "saves a Data Room root as shared and lists it after reload for another reader" do
      create_folder(view: "data_room")

      expect(response).to have_http_status(:ok)
      folder = Droom::Folder.find_by!(name: "Creation regression").reload
      expect(folder.data_room?).to be true
      expect(folder.parent_id).to be_nil
      expect(folder.created_by).to eq(viewer)
      expect(folder.documents).to be_empty
      expect(response.body).to include("folder_#{folder.uid}")

      reader = FactoryGirl.create(:user)
      reader.stub(:permitted?).and_return(false)
      reader.stub(:permitted?).with("droom.library.read").and_return(true)
      expect(folder.accessible_to?(reader)).to be true
      ability = Object.new.extend(CanCan::Ability)
      ability.can :read, [Droom::Folder, Droom::Document, Droom::Link]
      controller.stub(:current_user).and_return(reader)
      controller.stub(:current_ability).and_return(ability)

      get :index, params: { view: "data_room" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("folder_#{folder.uid}")
      expect(response.body.scan(/name=['"]view['"]/).size).to eq(1)
    end

    it "keeps myLibrary root creation private even when a sharing flag is submitted" do
      post :create, params: { view: "my_library", folder: { name: "Private creation", data_room: true } }, format: :html

      expect(response).to have_http_status(:ok)
      folder = Droom::Folder.find_by!(name: "Private creation").reload
      expect(folder.data_room?).to be false
      expect(Droom::Folder.roots.data_room).not_to include(folder)
    end

    it "uses the submitted parent on the non-nested form POST and inherits its sharing" do
      parent = FactoryGirl.create(:folder, name: "Shared parent", data_room: true)
      create_folder(view: "data_room", parent: parent)

      expect(response).to have_http_status(:ok)
      folder = parent.children.find_by!(name: "Creation regression").reload
      expect(folder.parent_id).to eq(parent.id)
      expect(folder.data_room?).to be true
      expect(Droom::Folder.roots).not_to include(folder)

      get :show, params: { id: parent.uid, view: "data_room" }

      expect(response.body).to include("folder_#{folder.uid}")
    end

    it "inherits sharing for a nested subfolder request" do
      parent = FactoryGirl.create(:folder, name: "Nested parent", data_room: true)
      post :create, params: { folder_id: parent.uid, view: "data_room", folder: { name: "Nested child" } }, format: :html

      expect(response).to have_http_status(:ok)
      folder = parent.children.find_by!(name: "Nested child").reload
      expect(folder.parent_id).to eq(parent.id)
      expect(folder.data_room?).to be true
    end

    it "does not share a private parent or its child implicitly" do
      parent = FactoryGirl.create(:folder, name: "Private parent", data_room: false)
      create_folder(view: "my_library", parent: parent)

      expect(response).to have_http_status(:ok)
      expect(parent.children.find_by!(name: "Creation regression").reload.data_room?).to be false
      expect(parent.reload.data_room?).to be false
    end

    it "rejects a private parent selected explicitly in Data Room view without writing" do
      parent = FactoryGirl.create(:folder, name: "Private parent", data_room: false)

      expect { create_folder(view: "data_room", parent: parent) }.not_to change(Droom::Folder, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("not shared with the data room")
      expect(parent.reload.data_room?).to be false
    end

    it "retains confidentiality when creating under a confidential shared parent" do
      parent = FactoryGirl.create(:folder, name: "Confidential parent", data_room: true, private: true)
      create_folder(view: "data_room", parent: parent)

      expect(response).to have_http_status(:ok)
      folder = parent.children.find_by!(name: "Creation regression").reload
      expect(folder.data_room?).to be true
      expect(folder.private?).to be true
      expect(parent.reload.private?).to be true
    end

    it "retains private creation from a legacy parent link without an explicit view" do
      parent = FactoryGirl.create(:folder, name: "Legacy private parent", data_room: false)
      session[:library_view] = "data_room"
      post :create, params: { folder: { name: "Private legacy child", parent_id: parent.id } }, format: :html

      expect(response).to have_http_status(:ok)
      expect(parent.children.find_by!(name: "Private legacy child").reload.data_room?).to be false
    end

    it "rejects conflicting nested and submitted parents without writing" do
      parent = FactoryGirl.create(:folder, name: "Selected parent", data_room: true)
      other_parent = FactoryGirl.create(:folder, name: "Other parent", data_room: true)

      expect {
        post :create, params: { folder_id: parent.uid, view: "data_room", folder: { name: "Conflicting destination", parent_id: other_parent.id } }, format: :html
      }.to raise_error(ActionController::BadRequest)
      expect(Droom::Folder.where(name: "Conflicting destination")).not_to exist
    end

    it "does not silently create a root when the submitted parent is missing" do
      expect {
        post :create, params: { view: "data_room", folder: { name: "Missing parent", parent_id: -1 } }, format: :html
      }.to raise_error(ActiveRecord::RecordNotFound)
      expect(Droom::Folder.where(name: "Missing parent")).not_to exist
    end

    it "rejects a parent the creator cannot update" do
      parent = FactoryGirl.create(:folder, name: "Unauthorised parent", data_room: true)
      ability = Object.new.extend(CanCan::Ability)
      ability.can :create, Droom::Folder
      controller.stub(:current_ability).and_return(ability)

      expect { create_folder(view: "data_room", parent: parent) }.to raise_error(CanCan::AccessDenied)
      expect(parent.children).to be_empty
    end

    it "returns a useful error on save failure and creates only one record on retry" do
      Droom::Folder.any_instance.stub(:save).and_return(false)
      Droom::Folder.any_instance.stub(:errors).and_return(double(full_messages: ["Sharing could not be saved"]))

      expect { create_folder(view: "data_room") }.not_to change(Droom::Folder, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Sharing could not be saved")

      Droom::Folder.any_instance.unstub(:save)
      Droom::Folder.any_instance.unstub(:errors)
      expect { create_folder(view: "data_room") }.to change(Droom::Folder, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect { create_folder(view: "data_room") }.not_to change(Droom::Folder, :count)
      expect(response).to have_http_status(:conflict)
    end

    it "carries the chosen view and numeric parent through the new-folder form" do
      parent = FactoryGirl.create(:folder, name: "Form parent", data_room: true)
      get :new, params: { folder_id: parent.uid, view: "data_room" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/name=['"]view['"][^>]*value=['"]data_room['"]|value=['"]data_room['"][^>]*name=['"]view['"]/)
      expect(assigns(:folder).parent_id).to eq(parent.id)
      expect(session[:library_view]).to eq("data_room")
      expect(response.body).to include(assigns(:folder).uid)
      expect(response.body).to include('creation_token')
    end

    it "reuses a creation token so retrying with an edited name cannot create another record" do
      token = SecureRandom.uuid
      create_folder(view: "data_room", token: token)

      expect(response).to have_http_status(:ok)
      expect(Droom::Folder.find_by!(name: "Creation regression").uid).to eq(token)
      expect { create_folder(view: "data_room", name: "Edited retry", token: token) }.not_to change(Droom::Folder, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(Droom::Folder.where(uid: token).count).to eq(1)
    end

    it "returns a conflict instead of success when a concurrent retry hits the UID index" do
      Droom::Folder.any_instance.stub(:save).and_raise(ActiveRecord::RecordNotUnique)

      expect { create_folder(view: "data_room", token: SecureRandom.uuid) }.not_to change(Droom::Folder, :count)
      expect(response).to have_http_status(:conflict)
      expect(response.body).to include("Refresh the destination")
    end

    it "rejects malformed creation tokens without saving a folder" do
      expect { create_folder(view: "data_room", token: "invalid") }.not_to change(Droom::Folder, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
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
