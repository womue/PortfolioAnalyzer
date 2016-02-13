#
# Project: PortfolioAnalyzer
# File: local_portfolios_analyzer.rb
#
# Description:
# PortfolioAnalyzer main file. Contains general functionalities.
#
# Author(s):
# Wolfgang Mueller, Univ. of Education Weingarten, MEVIS (mueller@md-phw.de)
#
# (c) Univ. of Education Weingarten, MEVIS, 2016
#
# Usage: ruby local_portfolios_analyzer
#

require 'fileutils'
require 'highline/import'

require_relative 'portfolio_analyzer_tools'

module LocalPortfoliosAnalyzer

  DEFAULT_PORTFOLIO_DOWNLOAD_DIR = "#{Dir.home}/MaharaPortfolios"

  say "Please enter the directory for local member portfolios storage:"
  portfolio_download_dir = ask('> ') { |q| q.default = DEFAULT_PORTFOLIO_DOWNLOAD_DIR }

  unless Dir.exists? portfolio_download_dir
    say "directory not found!"
    Kernel.exit(1)
  end

  # extract available groups
  group_dirnames = Dir.entries(portfolio_download_dir).delete_if { |name| name.match(/^\./) }

  puts "#{group_dirnames.length} groups found"

  groupid = PortfolioAnalyzerTools.select_choice("Select mahara group for analysis", group_dirnames)

  group_dirname = group_dirnames[groudid]

  # extract group members
  group_member_dirs = Dir.entries(group_dirname).delete_if { |name| name.match(/^\./) }


end