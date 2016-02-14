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
require 'sanitize'

require_relative 'jsonable'
require_relative 'portfolio_analyzer_tools'
require_relative 'html_to_plain_text'

class PortfolioView < Jsonable
  attr_accessor :url, :page, :portfolio_title, :title
  attr_accessor :local_storage_dir

  # Constructs a PortfolioView instance
  # Params:
  # - url: internal Mahara url of this view
  # - page: the page belonging to this view
  # - portfolio_title: title of the portfolio this view belongs to
  # - view_title: title of this view
  def initialize url=nil, page=nil, portfolio_title=nil, view_title=nil
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

  # override to_json to include a special handling of pages (which are not serialized)
  def to_json_old(*a)
    hash = {}
    self.instance_variables.each do |var|
      hash[var] = self.instance_variable_get var unless (var == :@page)
    end
    hash.to_json(*a)
  end

  def to_json_new(*a)
    res = {'json_class' => self.class.name}
    hash = {}
    self.instance_variables.each do |var|
      hash[var] = self.instance_variable_get var unless (var == :@page)
    end
    res['data'] = hash
    res.to_json(*a)
  end

  # Save the whole page to a local file
  # Params:
  # - agent: mechanize agent to perform the download; this one should been authorized to access the member pages via a login
  # - path: the path to store the data
  def save agent, path
    say "saving view '#{title}' to #{path} ..."
    agent.pluggable_parser.default = Mechanize::Download
    agent.get(url).save(path)
  end

  def nokogiri_doc
    @page.parser
  end

  def html
    nokogiri_doc.to_s
  end

  def text
    #res = html.gsub(/<\/?[^>]*>/, ' ').gsub(/\n\n+/, '\n').gsub(/^\n|\n$/, ' ').squish!
    text = Sanitize.clean(html, remove_contents: ['script', 'style'])
    res = HtmlToPlainText.convert_to_text(text)
    # puts "in PortfolioView.text: #{res}"
    res
  end

  # Generates a hash representation for the specified view connected to the specified member, suitable
  # for passing to Solr for adding as a document
  def to_solr(member)
    {:url => @url, :text => text, :portfolio_title => @portfolio_title,
     :title => @title, :local_storage_dir => @local_storage_dir, :author => member.name}
  end

  def ==(obj)
    (@page == obj.page) and (@portfolio_title == obj.portfolio_title) and (@title == obj.title) and (@url = obj.url)
  end

end