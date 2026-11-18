require 'minitest/autorun'
require 'active_support/all'
require 'ostruct'
module Droom; module Concerns; end; end
require_relative '../../app/models/droom/concerns/person_identity_sync'

class UsersFirstNameTest < Minitest::Test
  class AccountDouble
    include Droom::Concerns::PersonIdentitySync
    attr_accessor :sync_in_progress
    attr_accessor :given_name, :person, :deliberate_given_name_change, :changed_name
    def person_for_identity_sync = person
    def saved_changes? = true
    def has_attribute?(key) = key == :given_name
    def saved_change_to_given_name? = changed_name
    def changed? = false
  end

  def account
    record = AccountDouble.new
    record.given_name = 'Chun Hei'
    record.changed_name = true
    record.person = OpenStruct.new(given_name: 'Alex', changed?: true, save: true)
    record
  end

  def test_imported_name_cannot_replace_core_name
    record = account
    record.sync_with_person
    assert_equal 'Alex', record.given_name
    assert_equal 'Alex', record.person.given_name
    refute record.person.deliberate_given_name_change
  end

  def test_deliberate_users_edit_carries_explicit_intent_to_core
    record = account
    record.deliberate_given_name_change = true
    record.sync_with_person
    assert_equal 'Chun Hei', record.person.given_name
    assert record.person.deliberate_given_name_change
    assert record.person.skip_user_sync
    refute record.deliberate_given_name_change
    refute record.sync_in_progress
  end

  def test_failed_core_save_does_not_report_success_or_leave_sync_disabled
    record = account
    record.deliberate_given_name_change = true
    record.person.save = false
    assert_raises(RuntimeError) { record.sync_with_person }
    refute record.sync_in_progress
    refute record.deliberate_given_name_change
  end
end
