require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::Document, :solr => true do

  context "Visibility:" do
    before :each do
      @document = FactoryGirl.create(:document)
      @user = FactoryGirl.create(:user)
      @event = FactoryGirl.create(:simple_event)
    end

    it "should not be visible to unlinked people" do
      Droom::Document.visible_to(@user).should_not include(@document)
    end

    describe "when linked" do
      before do
        @document.attach_to(@event)
        @invitation = @user.invite_to(@event)
      end

      it "should be visible to linked people" do
        pending "change to rules on who can see what"
        Droom::Document.visible_to(@user).should include(@document)
      end

      it "should become invisible when people are deinvited" do
        @invitation.destroy
        Droom::Document.visible_to(@user).should_not include(@document)
      end

      it "should become invisible when detached" do
        @document.detach_from(@event)
        Droom::Document.visible_to(@user).should_not include(@document)
      end
    end

  end

  describe ".accessible_to" do
    it "allows an administrator to access every document" do
      administrator = FactoryGirl.create(:user, admin: true)
      document = FactoryGirl.create(:document)

      Droom::Document.accessible_to(administrator).should include(document)
    end

    it "allows a user to access a document in a directly shared folder" do
      user = FactoryGirl.create(:user)
      folder = FactoryGirl.create(:folder)
      document = FactoryGirl.create(:document, folder: folder)
      Droom::Share.create!(shareable: folder, shared_with: user, shared_by: FactoryGirl.create(:user))

      document.accessible_to?(user).should be_true
    end

    it "allows a user to access a directly shared document" do
      user = FactoryGirl.create(:user)
      document = FactoryGirl.create(:document)
      Droom::Share.create!(shareable: document, shared_with: user, shared_by: FactoryGirl.create(:user))

      document.accessible_to?(user).should be_true
    end

    it "allows a user to access a document in a descendant of a shared folder" do
      user = FactoryGirl.create(:user)
      shared_folder = FactoryGirl.create(:folder)
      descendant = shared_folder.children.create!(slug: "document-descendant")
      document = FactoryGirl.create(:document, folder: descendant)
      Droom::Share.create!(shareable: shared_folder, shared_with: user, shared_by: FactoryGirl.create(:user))

      document.accessible_to?(user).should be_true
    end

    it "denies an unrelated data room user access without a share" do
      data_room_user = FactoryGirl.create(:user)
      data_room_user.stub(:data_room_user?).and_return(true)
      document = FactoryGirl.create(:document, data_room: true)

      document.accessible_to?(data_room_user).should be_false
    end
  end
end
