require 'test/unit'
require 'highline/import'

require_relative 'mahara_accessor'

MOOPAED_LOGIN_URL = 'https://www.moopaed.de/moodle/login/index.php'
MAHARA_DASHBOARD_URL = 'https://www.moopaed.de/moodle/auth/mnet/jump.php?hostid=3'

class MaharaAccessorTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    username = 'rebholzwg'
    password = 'tramore'
    @ga = MaharaAccessor.new(username, password, MOOPAED_LOGIN_URL, MAHARA_DASHBOARD_URL)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  # Fake test
  def test_open_mahara
    assert_not_nil(@ga.open_mahara, "mahara successfully opened")
  end

  def test_extract_group_names
    mahara_page = @ga.open_mahara
    assert_not_nil( @ga.extract_group_links, "mahara group links extracted")
  end

  def test_find_user
    user_name = 'Karl Barth'
    mahara_page = @ga.open_mahara
    users = @ga.find_user(user_name)
    assert_not_nil(users, "user not found. Search result is nil.")
    assert_not_empty(users, "User not found. Result list is empty.")
    assert_equal(MaharaMember, users.first.class, "Wrong class type in result list.")
    assert_true(users.first.name.include?(user_name), "Requested user is not in result list.")
  end

end