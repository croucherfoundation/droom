require 'minitest/autorun'
require 'active_support/all'
require 'ostruct'
require 'erb'
require_relative '../../app/services/core_identity_lookup'
class Person
  class << self
    attr_accessor :status, :identity, :requested_path
    def get_raw(path)
      self.requested_path = path
      yield({}, OpenStruct.new(status: status))
    end
    def new_from_parsed_data(data) = identity
  end
end
class CoreIdentityLookupTest < Minitest::Test
  def setup
    @user = OpenStruct.new(uid: 'fictional-user')
    Person.identity = OpenStruct.new(uid: 'fictional-person')
  end
  def test_exact_lookup_does_not_depend_on_search
    Person.status = 200
    assert_equal Person.identity, CoreIdentityLookup.for_user(@user)
    assert_equal '/api/people/user/fictional-user', Person.requested_path
  end
  def test_only_missing_person_allows_creation
    Person.status = 404
    assert_nil CoreIdentityLookup.for_user(@user)
    [401, 500, 503].each do |status|
      Person.status = status
      assert_raises(RuntimeError) { CoreIdentityLookup.for_user(@user) }
    end
  end
  def test_invalid_success_does_not_allow_replacement
    Person.status = 200
    Person.identity = OpenStruct.new(uid: nil)
    assert_raises(RuntimeError) { CoreIdentityLookup.for_user(@user) }
  end
end
