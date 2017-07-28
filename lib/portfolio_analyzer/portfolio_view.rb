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

require 'time'
require 'json'
require 'json/add/core'
require 'words_counted'
require 'sanitize'
require 'mechanize'

require_relative 'jsonable'
require_relative 'logging.rb'
require_relative 'portfolio_analyzer_tools'
require_relative 'html_to_plain_text'
require_relative 'portfolio_statistics'

# @attr [String] url
# @attr [Mechanize::Page] page
# @attr [String] portfolio_title
# @attr [String] title
class PortfolioView < Jsonable
  include Logging

  attr_accessor :url, :page, :portfolio_title, :title, :member_name, :group_name
  attr_accessor :local_storage_dir, :analyzer

  # Constructs a PortfolioView instance
  # Params:
  # - url: internal Mahara url of this view
  # - page: the page belonging to this view
  # - portfolio_title: title of the portfolio this view belongs to
  # - view_title: title of this view
  # @param [String] url
  # @param [Mechanize::Page] page
  # @param [String] member_name
  # @param [String] portfolio_title
  # @param [String] view_title
  # @param [String] group_name
  def initialize url=nil, page=nil, member_name=nil, portfolio_title=nil, view_title=nil, group_name=nil
    @url = url
    @page = page
    @member_name = member_name
    @portfolio_title = portfolio_title
    @title = view_title
    @group_name = group_name
    @time_indexed = Time::now
    @analyzer = PortfolioStatistics::DescriptiveViewAnalyzer.new
  end

  # Returns the user's image nodes on this page.
  def get_stats
    @analyzer.get_stats(self)
  end

  # Returns the uploaded images in this view
  def uploaded_images
    @analyzer.uploaded_images(self)
  end

  # deprecated - not used!
  def to_json_new(*a)
    res = {'json_class' => self.class.name}
    hash = {}
    self.instance_variables.each do |var|
      hash[var] = self.instance_variable_get var unless (var == :@page)
    end
    res['data'] = hash
    res.to_json(*a)
  end

  def self.json_create obj
    logger.debug "calling 'json_create' for super class ..."
    res_obj = super obj
    res_obj
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
    puts "nokogiri_doc: page is #{@page.class.to_s}"
    puts @page
    @page.parser
  end

  def html
    nokogiri_doc.to_s
  end

  # Returns a plain text representation of the view
  def text
    #res = html.gsub(/<\/?[^>]*>/, ' ').gsub(/\n\n+/, '\n').gsub(/^\n|\n$/, ' ').squish!
    # text = Sanitize.clean(html, :remove_contents => ['script', 'style'])
    text = Sanitize.clean(html)
    HtmlToPlainText.convert_to_text(text)
  end

  # Generates a hash representation for the specified view connected to the specified member, suitable
  # for passing to Solr for adding as a document
  def to_solr
    res = {:url => @url, :text => text, :portfolio_title => @portfolio_title, :portfolioTitle => @portfolioTitle,
           :title => @title, :local_storage_dir => @local_storage_dir, :author => @member_name, :group => @group_name, :indexDate => @time_indexed.utc.iso8601}
    res = res.merge(get_stats)
    return res
  end

  def ==(obj)
    (@page == obj.page) and (@portfolio_title == obj.portfolio_title) and (@title == obj.title) and (@url = obj.url)
  end

end