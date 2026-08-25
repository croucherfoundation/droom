require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::UsersController, type: :controller do
  routes { Droom::Engine.routes }

  let(:viewer) { FactoryGirl.create(:user) }
  let(:target) { FactoryGirl.create(:user) }

  before do
    controller.stub(:current_user).and_return(viewer)
    controller.stub(:user_signed_in?).and_return(true)
    controller.stub(:check_data_room_permission)
    controller.stub(:check_user_is_confirmed)
    controller.stub(:check_user_setup)
  end

  describe "GET #show" do
    it "allows a user to view their own profile" do
      get :show, params: { id: viewer.id, format: :json }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(viewer.email)
    end

    it "allows an administrator to view another user's profile" do
      viewer.update!(admin: true)

      get :show, params: { id: target.id, format: :json }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(target.email)
    end

    it "returns the same not-found response for an unrelated user and a missing user" do
      get :show, params: { id: target.id, format: :json }
      unauthorized_status = response.status
      unauthorized_body = response.body

      get :show, params: { id: target.id + 10_000, format: :json }

      expect(unauthorized_status).to eq(response.status)
      expect(unauthorized_body).to eq(response.body)
      expect(response).to have_http_status(:not_found)
      expect(unauthorized_body).not_to include(target.email)
      expect(unauthorized_body).not_to include(target.phone.to_s)
      expect(unauthorized_body).not_to include(target.address.to_s)
    end
  end
end
