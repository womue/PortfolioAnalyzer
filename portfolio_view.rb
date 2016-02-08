#
# Project: portfolio_analyer
# File: PortfolioView
#
# Description:
# Base class for a portfolio view
#
# Author(s):
# Wolfgang Mueller, Univ. of Education Weingarten, MEVIS (mueller@md-phw.de)
#
# (c) Univ. of Education Weingarten, MEVIS, 2016
#

require 'json'
require 'json/add/core'
require 'words_counted'

require_relative 'jsonable'

class PortfolioView < Jsonable
  attr_reader :owner, :url, :page, :portfolio_title, :title
  attr_accessor :local_storage_dir

  # Constructs a PortfolioView instance
  # Params:
  # - owner: name of the Mahara member owning this view
  # - url: internal Mahara url of this view
  # - portfolio_title: title of the portfolio this view belongs to
  # - view_title: title of this view
  def initialize owner, url, page, portfolio_title, view_title
    @owner = owner
    @url = url
    @page = page
    @portfolio_title = portfolio_title
    @title = view_title
  end

  # Returns the user's image nodes on this page.
  def uploaded_images
    page.images_with(:src => /download/)
  end

  # returns the number of images on this page
  # TODO exclude standard Mahara template images
  def image_count
    page.images.length
  end

  # Returns the user's link nodes on this page.
  def links
    page.links_with(:src => /download/)
  end

  # Returns the number of words on this page.
  def words
    counter = WordsCounted::Counter.new @page.text
    return counter.word_count
  end

  # Save the whole page to a local file
  # Params:
  # - agent: mechanize agent to perform the download; this one should been authorized to access the member pages via a login
  # - path: the path to store the data
  def save agent, path
    agent.pluggable_parser.default = Mechanize::Download
    agent.get(url).save(path)
  end
end