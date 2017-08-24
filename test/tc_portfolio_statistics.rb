require 'test/unit'
require 'mechanize'

require_relative '../lib/portfolio_analyzer/portfolio_statistics'

class PortfolioStatisticsTest < Test::Unit::TestCase
  @agent = nil
  @page = nil
  @analyzer = nil
  @view = nil

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @agent = Mechanize.new
    uri = URI.join('file:///', File.absolute_path("test/data/view.html"))
    @page = @agent.get uri.to_s
    @view = PortfolioView.new uri.to_s, @page, "test mameber", "test portfolio", "View1", "testgroup"

    @analyzer = PortfolioStatistics::DescriptiveViewAnalyzer.new
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  # test of simple stats based on example document
  def test_stats
    assert @page != nil

    wc = @analyzer.word_count @view
    puts wc
    # word count from MS Word: 3.648 (including UI text from Mahara)
    assert_equal 3759, wc

    external_links = @analyzer.external_links @view
    puts "external links: #{external_links.size}"
    # external_links.each do |link|
    #  puts "> " + link.uri.to_s
    # end

    images = @analyzer.images @view
    puts "images: #{images.size}"
    # images.each do |image|
    #   puts "> " + image.to_s
    # end

    uploaded_images = @analyzer.uploaded_images @view
    puts "uploaded_images: #{uploaded_images.size}"

    wikipedia_images = @analyzer.images_from_domain(@view, "wikipedia")
    puts "wikipedia_images: #{wikipedia_images.size}"
  end

  def test_get_stats
    res = @analyzer.get_stats @view
    assert_equal res.size, 9
  end


end