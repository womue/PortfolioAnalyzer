require 'test/unit'
require 'highline/import'

require_relative 'group_analyzer'

class GroupAnalyzerTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    username = 'Please insert your moopaed username here'
    password = 'Please insert your moopaed password here'
    @ga = GroupAnalyzer.new( username, password)
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
end