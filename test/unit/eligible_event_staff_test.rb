require 'minitest/autorun'
require 'minitest/mock'

class EligibleEventStaffTest < Minitest::Test
  StaffRecord = Struct.new(:uid, :name, :given_name, :family_name)

  class OfficeScope
    attr_reader :joined, :conditions, :distinct_called

    def initialize(records)
      @records = records
    end

    def joins(association)
      @joined = association
      self
    end

    def where(conditions)
      @conditions = conditions
      self
    end

    def distinct
      @distinct_called = true
      self
    end

    def in_name_order
      @records
    end
  end

  def test_admin_gets_only_the_minimal_office_staff_payload
    scope = OfficeScope.new([StaffRecord.new('office-1', 'Office Staff', 'Office', 'Staff')])
    controller = Droom::Api::UsersController.new
    payload = nil

    controller.stub(:current_user, Struct.new(:admin?).new(true)) do
      Droom::User.stub(:undeleted, scope) do
        controller.stub(:render_api_success, ->(**values) { payload = values }) do
          controller.eligible_event_staff
        end
      end
    end

    assert_equal :groups, scope.joined
    assert_equal({ droom_groups: { slug: 'croucher-office' } }, scope.conditions)
    assert scope.distinct_called
    assert_equal [{ uid: 'office-1', name: 'Office Staff', given_name: 'Office', family_name: 'Staff' }], payload[:users]
  end

  def test_non_admin_is_denied_before_the_directory_query
    controller = Droom::Api::UsersController.new
    controller.stub(:current_user, Struct.new(:admin?).new(false)) do
      Droom::User.stub(:undeleted, -> { flunk 'Forbidden caller queried staff' }) do
        assert_raises(Droom::AccessDenied) { controller.eligible_event_staff }
      end
    end
  end
end