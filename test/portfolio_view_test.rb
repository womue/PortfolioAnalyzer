require 'test/unit'
require 'json'
require 'mechanize'
require 'nokogiri'

require_relative '../lib/portfolio_analyzer/portfolio_view'

class PortfolioViewTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @pv = PortfolioView.new :url, :page, :portfolio_title, :view_title
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  # json serialization test
  def test_to_json
    json_s = @pv.to_json
    puts "generated by to_json: " + json_s
    puts "generated by JSON.dump: " + JSON.dump(@pv)
    #assert_equal("{\"json_class\":\"PortfolioView\",\"data\":{\"@url\":{\"json_class\":\"Symbol\",\"s\":\"url\"},\"@page\":{\"json_class\":\"Symbol\",\"s\":\"page\"},\"@portfolio_title\":{\"json_class\":\"Symbol\",\"s\":\"portfolio_title\"},\"@title\":{\"json_class\":\"Symbol\",\"s\":\"view_title\"}}}", json_s)

    obj = JSON.load(json_s)
    #obj = PortfolioView.from_json! json_s
    assert_equal(@pv, obj)
  end

  def test_nokogiri_access
    agent = Mechanize.new
    url = 'http://www.md-phw.de'
    mechanize_page = agent.get(url)
    pv = PortfolioView.new url, mechanize_page, "test_nokogiri_access", "test"
    nokogiri_doc = pv.nokogiri_doc
    assert(nokogiri_doc.is_a?(Nokogiri::HTML::Document))
    html = pv.html
    assert(html.is_a?(String))
    assert(html.match(/^<!DOCTYPE html>/))
    text = pv.text
    assert(text.is_a?(String))
    assert(text.match(/^<!DOCTYPE html>/) == nil)
  end
end