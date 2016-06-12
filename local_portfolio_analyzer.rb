#
# Project: PortfolioAnalyzer
# File: local_portfolio_analyzer.rb
#
# Description:
# LocalPortfolioAnalyzer main file. Contains general functionalities for reading stored data from PortfolioAnalyzer and
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
require 'fastimage'
require 'find'

require 'mechanize'

require_relative 'portfolio_analyzer_tools'
require_relative 'mahara_member'
require_relative 'portfolio_view'
require_relative 'portfolio_statistics'

DEFAULT_PORTFOLIO_DOWNLOAD_DIR = "#{Dir.home}/MaharaPortfolios"

CSV_SUMMARY_FILE_NAME = "Summary3.csv"
MEMBER_STATS_FILE_PREFIX = "Details-"

module LocalPortfolioAnalyzer
  def self.get_parameter_from_option_or_ask(option_value, msg, default_value=nil, echo=true)
    return option_value unless option_value == nil
    say msg
    ask('> ') { |q| q.default = default_value; q.echo = echo }
  end

  # Update the img nodes of the HTML document to link to the locally stored image files
  # Parameters:
  # - path_to_view:      the absolute path to the HTML document of the view
  # - page:              the Nokogiri page representing the HTML document
  # - img_download_dir: the absolute path to the local directory containing the image artefacts
  def self.adapt_image_src(path_to_view, page, img_download_dir)
    # Look for all uploaded images
    artefact_images = page.images_with(:src => /download/)

    artefact_images.each do |image|
      basenamematch = /(?<=\?)[A-Za-z0-9=.]*/.match(File.basename image.uri.to_s)
      break unless basenamematch != nil
      basename = basenamematch[0]
      # image_download_path = img_download_dir + "/" + basename
      # puts image_download_path

      # determine full image file name (including suffix)
      image_file_name = nil
      Find.find(img_download_dir) do |path|
        if File.basename(path).start_with?(basename)
          image_file_name = File.basename(path)
          break
        end
      end

      # update src attribute of image node
      if image_file_name != nil
        node = image.node
        node["src"] = "../uploaded_images/" + image_file_name
      end

    end
    # write manipulated HTML document
    html_file = File.open(path_to_view + ".lokal", "w")
    html_file << page.parser.to_html

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
    opt.on('-i', '--embed_local_images') { |o| options[:embed_local_images] = "y" }
  end.parse!

  logger.info "download images: #{options[:download_images]}"

  download_images = get_parameter_from_option_or_ask(options[:download_images], "Download uploaded view images? : ", "n") == "y"

  logger.info "downloading view images ..." if download_images

  embed_local_images = get_parameter_from_option_or_ask(options[:embed_local_images], "Embed local images in view? : ", "n") == "y"
  #embed_local_images = true
  logger.info "Embedding local images in view ..." if embed_local_images

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
    view_nr = 0
    agent = Mechanize.new()
    member.views.each do |view|
      logger.info "reconstructing view nr #{view_nr}"
      view_id = "views/view#{view_nr}.html"
      path = "file:" + member.local_dir + "/" + view_id
      page = agent.get path
      view.page = page
      if embed_local_images then adapt_image_src(member.local_dir + "/" + view_id, view.page, member.local_dir + "/uploaded_images") end
      view_nr += 1
    end
  end

  analyzers = [PortfolioStatistics::DescriptiveAnalyzer.new]


  # create CSV table summarizing member portfolios
  csv_summary_filename = group_dir + "/" + CSV_SUMMARY_FILE_NAME
  begin
    CSV.open(csv_summary_filename, "wb", {:col_sep => ";"}) do |csv|
      column_titles = ["Nummer", "Name", "# Views"]
      analyzers.each do |analyzer|
        column_titles = column_titles + analyzer.get_column_titles
      end
      logger.debug 'column_titles: #{column_titles}'
      csv << column_titles
      i = 1
      member_entries.each do |member|
        csv_member_filename = group_dir + "/" + MEMBER_STATS_FILE_PREFIX + member.name + ".csv"
        CSV.open(csv_member_filename, "wb", {:col_sep => ";"}) do |detail_file|
          outline_analyzer = PortfolioStatistics::OutlineAnalyzer.new
          detail_file << ["Name"] + outline_analyzer.get_column_titles
          detail_file << ([member.name] + outline_analyzer.get_stats(member))
          detail_file << ['']
          table = outline_analyzer.get_view_stats member
          table.each do |row|
              detail_file << row
          end
          detail_file << ['']
          table = outline_analyzer.external_links_list member
          table.each do |row|
            detail_file << row
          end
          detail_file << ['']
          table = outline_analyzer.get_outline member
          table.each do |row|
            detail_file << row
          end

        end
        #end
        data_row = [i, member.name, member.views.length]
        analyzers.each do |analyzer|
          data_row = data_row + analyzer.get_stats(member)
        end
        csv << data_row
        i = i + 1
      end
    end
  rescue RuntimeError => e
    logger.error "ERROR: could not write CSV summary file to '#{csv_summary_filename}': " + e.to_s
    logger.error e.backtrace
  end

  logger.info "done"

end