#
# Project: PortfolioAnalyzer
# File: portfolio_reanalyzer.rb
#
# Description:
# PortfolioReanalyzer main file. Contains general functionalities for reading stored data from PortfolioAnalyzer and
# performing additional analysis
#
# Author(s):
# Wolfgang Mueller, Univ. of Education Weingarten, MEVIS (mueller@md-phw.de)
#
# (c) Univ. of Education Weingarten, MEVIS, 2016
#
# Usage: ruby portfolio_reanalyzer
#

require 'rubygems'
require 'fileutils'
require 'logger'
require 'optparse'
require 'highline/import'
require 'csv'

require_relative 'portfolio_analyzer_tools'
require_relative 'mahara_member'
require_relative 'portfolio_view'

DEFAULT_PORTFOLIO_DOWNLOAD_DIR = "#{Dir.home}/MaharaPortfolios"

module PortfolioReanalyzer
  def self.get_parameter_from_option_or_ask(option_value, msg, default_value=nil, echo=true)
    return option_value unless option_value == nil
    say msg
    ask('> ') { |q| q.default = default_value; q.echo = echo }
  end

  # set up logger
  logger = Logger.new(STDOUT)
  #logger.level = Logger::WARN
  logger.level = Logger::DEBUG

  # parse options
  options = {}
  OptionParser.new do |opt|
    opt.on('-d', '--local_dir LOCAL_PORTFOLIO_DIR') { |o| options[:local_dir] = o }
    opt.on('-a', '--download_images') { |o| options[:download_images] = "y" }
  end.parse!

  logger.info "download images: #{options[:download_images]}"

  download_images = get_parameter_from_option_or_ask(options[:download_images], "Download uploaded view images? : ", "n") == "y"

  logger.info "downloading view images ..." if download_images

  portfolio_download_dir = get_parameter_from_option_or_ask(options[:local_dir], "Please enter the directory for local member portfolios storage:", DEFAULT_PORTFOLIO_DOWNLOAD_DIR)
  logger.info "using portfolio download dir '#{portfolio_download_dir}'"

  unless Dir.exists? portfolio_download_dir then
    logger.error "ERROR: local portfolio directory '#{portfolio_download_dir}' not found!"
    System.exit(1)
  end

  # select group for analysis
  group_entries = []
  Dir.entries(portfolio_download_dir).each do |entry|
    absolute_path_name = File.expand_path(entry, portfolio_download_dir)
    group_entries << entry if File.directory?(absolute_path_name) and not entry[0] == "."
  end

  groupid = PortfolioAnalyzerTools.select_choice("Select mahara group for analysis", group_entries)
  group_dir = portfolio_download_dir + '/' + group_entries[groupid]

  # load members
  # select group for analysis
  member_entries = []
  Dir.entries(group_dir).each do |entry|
    path = group_dir + "/" + entry
    if File.directory?(path) and not entry[0] == "." then
      logger.debug "member found: #{entry}" if File.directory?(path) and not entry[0] == "."

      # recreate member
      member = MaharaMember.load path
      member_entries << member
    end
  end

  # for all members, reconstruct the available portfolios
  member_entries.each do |member|
    logger.info "member: #{member.name}  #views: #{member.views.length.to_s}"
    member.views.each do |view|
      logger.info "view type: #{view.class.to_s}"
      logger.info view.to_s
    end
  end

end