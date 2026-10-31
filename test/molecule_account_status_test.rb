require 'minitest/autorun'

class MoleculeAccountStatusTest < Minitest::Test
  Account = Struct.new(:deleted?, :active_for_authentication?)

  def test_only_an_undeleted_authenticable_account_is_active
    [[false, true, true], [true, true, false], [false, false, false], [true, false, false]].each do |deleted, authenticable, expected|
      actual = Droom::UserSerializer.new(Account.new(deleted, authenticable)).molecule_account_active
      assert_equal expected, actual
    end
  end
end
