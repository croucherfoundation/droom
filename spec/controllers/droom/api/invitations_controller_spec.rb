require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::Api::InvitationsController, type: :controller do
  routes { Droom::Engine.routes }

  let(:event_type) { Droom::EventType.find_or_create_by!(slug: "screening", name: "Screening") }
  let(:event) do
    Droom::Event.create!(
      name: "Test Screening Event",
      start: 1.week.from_now,
      event_type: event_type
    )
  end
  let(:user) { FactoryGirl.create(:user) }

  describe "POST #create" do
    it "creates an invitation for a user to an event" do
      post :create, params: { event_id: event.id, invitation: { user_id: user.id } }
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["invitation"]["event_id"]).to eq(event.id)
      expect(json["invitation"]["user_id"]).to eq(user.id)
    end

    it "returns existing invitation without duplicating" do
      event.invitations.create!(user: user)
      post :create, params: { event_id: event.id, invitation: { user_id: user.id } }
      expect(response).to have_http_status(:ok)
      expect(event.invitations.where(user: user).count).to eq(1)
    end
  end

  describe "DELETE #destroy" do
    it "removes an invitation" do
      invitation = event.invitations.create!(user: user)
      delete :destroy, params: { event_id: event.id, id: invitation.id }
      expect(response).to have_http_status(:ok)
      expect(event.invitations.where(user: user)).to be_empty
    end
  end
end
