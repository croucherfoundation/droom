require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::Folder do

	describe ".accessible_to" do
		it "allows an administrator to access every folder" do
			administrator = FactoryGirl.create(:user, admin: true)
			folder = FactoryGirl.create(:folder)

			Droom::Folder.accessible_to(administrator).should include(folder)
		end

		it "allows a user to access a folder they created" do
			user = FactoryGirl.create(:user)
			folder = FactoryGirl.create(:folder, created_by: user)

			folder.accessible_to?(user).should be_true
		end

		it "allows a user to access a directly shared folder" do
			user = FactoryGirl.create(:user)
			folder = FactoryGirl.create(:folder)
			Droom::Share.create!(shareable: folder, shared_with: user, shared_by: FactoryGirl.create(:user))

			folder.accessible_to?(user).should be_true
		end

		it "allows a user to access a descendant of a shared folder" do
			user = FactoryGirl.create(:user)
			shared_folder = FactoryGirl.create(:folder)
			descendant = shared_folder.children.create!(slug: "shared-descendant")
			Droom::Share.create!(shareable: shared_folder, shared_with: user, shared_by: FactoryGirl.create(:user))

			descendant.accessible_to?(user).should be_true
		end

		it "allows a user to access a legacy personal folder" do
			user = FactoryGirl.create(:user)
			folder = FactoryGirl.create(:folder)
			user.personal_folders.create!(folder: folder)

			folder.accessible_to?(user).should be_true
		end

		it "denies an unrelated data room user access without a share" do
			data_room_user = FactoryGirl.create(:user)
			data_room_user.stub(:data_room_user?).and_return(true)
			folder = FactoryGirl.create(:folder, data_room: true)

			folder.accessible_to?(data_room_user).should be_false
		end
	end

end
