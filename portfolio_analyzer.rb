#
# Project: PortfolioAnalyzer
# File: portfolio_analyzer.rb
#
# Description:
# PortfolioAnalyzer main file. Contains general functionalities.
#
# Author(s):
# Wolfgang Mueller, Univ. of Education Weingarten, MEVIS (mueller@md-phw.de)
#
# (c) Univ. of Education Weingarten, MEVIS, 2016
#
# Usage: ruby portfolio_analyzer
#

require 'rubygems'
require 'fileutils'
require 'optparse'
require 'highline/import'
require 'fastimage'
require 'rsolr'
require 'csv'

require_relative 'portfolio_analyzer_tools'
require_relative 'mahara_accessor'
require_relative 'mahara_member'

MOOPAED_LOGIN_URL = 'https://www.moopaed.de/moodle/login/index.php'
MAHARA_DASHBOARD_URL = 'https://www.moopaed.de/moodle/auth/mnet/jump.php?hostid=3'

DEFAULT_PORTFOLIO_DOWNLOAD_DIR = "#{Dir.home}/MaharaPortfolios"

DEFAULT_SOLR_PORT = 8983
DEFAULT_SOLR_URL = "http://localhost:#{DEFAULT_SOLR_PORT}/solr/MaharaPortfolio/"

CSV_SUMMARY_FILE_NAME = "Summary.csv"

module PortfolioAnalyzer


  # determines the suffix for image files for an image type
  # params:
  # - image_type: the id of the type for which the suffix shall be determined
  def self.suffix_for_image_type(image_type)
    case image_type
      when :png
        return ".png"
      when :gif
        return ".gif"
      when :jpeg
        return ".jpg"
      when :svg
        return ".svg"
      when :bmp
        return ".bmp"
      else
        say "suffix_for_image_type: warning - unknown image type: " + image_type.to_s
    end
  end

  def self.get_parameter_from_option_or_ask(option_value, msg, default_value=nil, echo=true)
    return option_value unless option_value == nil
    say msg
    ask('> ') { |q| q.default = default_value; q.echo = echo }
  end

  # Handles uploaded images found in a scraped Mahara view. These images are all
  # downloaded to allow for offline access. In addition, references of such uploaded images in the view
  # are adapted to link to the downloaded ones.
  # TODO: the image link adaption is currently not functioning; this needs to be fixed!
  # params:
  # - img_download_dir: the directory, to where the images shall be downloaded
  # - nokogiri_doc: the nokogiri representation of the page view
  # - the corresponding portfolio view object
  def self.handle_view_images(img_download_dir, mahara_accessor, portfolio_view)
    nokogiri_doc = mahara_accessor.agent.page.parser

    portfolio_view.uploaded_images.each do |image|
      image_type = nil
      basenamematch = /(?<=\?)[A-Za-z0-9=.]*/.match(File.basename image.uri.to_s)
      break unless basenamematch != nil
      basename = basenamematch[0]
      image_download_path = img_download_dir + "/" + basename

      say "saving image to #{image_download_path} ..."
      begin
        image.fetch.save image_download_path
      rescue Mechanize::ResponseCodeError => ex
        puts "An error of type #{ex.class} happened, message is #{ex.message}"
      end

      # try determining image type after download ... it did not work doing this before ... :-(
      begin
        image_type = FastImage.type(image_download_path, :raise_on_failure => true)
      rescue FastImage::FastImageException => e
        say "error identifying image type: " + e.to_s
      end

      new_image_download_path = image_download_path + suffix_for_image_type(image_type) unless (image_type == nil)

      # rename image file now to contain the correct image suffix
      if (image_type != nil) then
        File.rename(image_download_path, new_image_download_path)
        image_download_path = new_image_download_path
      end

      # adapt image urls in page document to match localy available uploaded_images

      # this is would we like to do, but working with mechanize apparently does not
      # provide us with the means to modify nodes directly ...
      # image.src = image_download_path
      #
      # therefore, we switch to the nokogiri API here
      tags = {
          'img' => 'src'
      }
      nokogiri_doc.search(tags.keys.join(',')).each do |node|
        url_param = tags[node.name]
        src = node[url_param]
        if (src == image.src) then
          puts "adapting view image #{src} to #{image_download_path}"
          node[url_param] = image_download_path
        end
      end
    end
  end

  def self.add_to_solr(member, portfolio_view, solr)
    puts "adding view to Solr ... " unless solr == nil
    puts portfolio_view.to_solr(member)
    solr.add portfolio_view.to_solr(member) unless solr == nil
    # solr.add :id=>1, :price=>1.00 unless solr == nil
    puts "done!" unless solr == nil
  end

  # parse options
  options = {}
  OptionParser.new do |opt|
    opt.on('-m', '--moodle_url MOODLE_URL') { |o| options[:moodle_url] = o }
    opt.on('-u', '--username USERNAME') { |o| options[:username] = o }
    opt.on('-p', '--password PASSWORD') { |o| options[:password] = o }
    opt.on('-d', '--local_dir LOCAL_PORTFOLIO_DIR') { |o| options[:local_dir] = o }
    opt.on('-s', '--solr_url SOLR_URL') { |o| options[:solr_url] = o }
    opt.on('-i', '--use_solr') { |o| options[:use_solr] = "y" }
    opt.on('-a', '--analyze_all') { |o| options[:analyze_all] = "y" }
  end.parse!

  portfolio_download_dir = get_parameter_from_option_or_ask(options[:local_dir], "Please enter the directory for local member portfolios storage:", DEFAULT_PORTFOLIO_DOWNLOAD_DIR)
  say "using portfolio download dir '#{portfolio_download_dir}'"

  FileUtils::mkdir_p portfolio_download_dir unless Dir.exists? portfolio_download_dir

  username = get_parameter_from_option_or_ask(options[:username], "Enter your username:  ")
  say "using username '#{username}'"

  # password = get_parameter_from_option_or_ask( options[:password], "Enter your password:  ", nil, "*")    # currently disabled for usage inside of RubyMine
  password = get_parameter_from_option_or_ask(options[:password], "Enter your password:  ", nil, true)

  mahara_accessor = MaharaAccessor.new(username, password, MOOPAED_LOGIN_URL, MAHARA_DASHBOARD_URL)
  agent = mahara_accessor.agent
  mahara_dashboard_page = mahara_accessor.open_mahara

  if (mahara_dashboard_page == nil) then
    puts "ERROR: unable to access Mahara dashboard page - user credentials possibly wrong!"
    Kernel.exit(1) if (groupid == group_links.length)
  end

  group_links = mahara_accessor.extract_group_links

  groupid = PortfolioAnalyzerTools.select_choice("Select mahara group for analysis", group_links)

  Kernel.exit(0) if (groupid == group_links.length)

  groupname = group_links[groupid].text
  grouplink = group_links[groupid].href

  group_download_dir = portfolio_download_dir + "/" + groupname.gsub(/\s/, '_')

  overwrite = false
  if (Dir.exists? group_download_dir) then
    # overwrite = agree("Download dir for Mahara portfolios for group #{groupname} exists! Overwrite data?", true)     # currently disabled for ussage inside of RubyMine
    say "Download dir for Mahara portfolios for group #{groupname} exists! Overwrite data? [y/n]"
    overwrite = ask('> ') { |q| q.default = 'y' } == 'y'
  end

  FileUtils::mkdir_p group_download_dir unless Dir.exists? group_download_dir or overwrite

  # say "Add views to Solr?:"
  # add_to_solr = ask('> ') { |q| q.default = 'y' } == 'y'
  add_to_solr = get_parameter_from_option_or_ask(options[:use_solr], "Add views to Solr?: ", "n") == "y"
  say "adding documents to solr" if add_to_solr

  solr_url = nil
  solr_url = get_parameter_from_option_or_ask(options[:solr_url], "Enter Solr URL: ", DEFAULT_SOLR_URL) if add_to_solr
  say "using solr server at '#{solr_url}'" if add_to_solr

  solr = nil
  solr = RSolr.connect :url => solr_url if (add_to_solr)
  if (solr == nil) then
    say "warning: connection to Solr could not be established!"
  end

  # extract members
  group_members = mahara_accessor.extract_group_members(grouplink, groupname)
  puts "extracted mumber of portfolio users: " + group_members.length.to_s

  # extract view information
  # TODO: the extract part should go somewhere to the MaharaAccessor class
  group_members.each do |member|
    puts "portfolios for member " + member.name

    member_download_dir = group_download_dir + "/" + member.name.gsub(/\s/, '_')
    # create member download dir if necessary
    if (not Dir.exist? member_download_dir) then
      begin
        Dir.mkdir member_download_dir
      rescue Exception => e
        say "error creating download dir for member " + member.name + ": " + e.to_s
        next
      end
    end

    mahara_user_views_page = agent.get(member.mainlink)

    # find block containing
    portfolios_block = mahara_user_views_page.css('.bt-myviews')[0]
    if (portfolios_block == nil) then
      puts "WARNING: portfolio view block '#{member.name}\'s Portfolios' not found on member's dashboard page"
      puts "Unable to extract portfolio view list!"
      next
    end

    portfolio_views = []
    i = 0
    views_download_dir = member_download_dir + "/views"
    FileUtils::mkdir_p views_download_dir unless Dir.exists? views_download_dir or overwrite
    img_download_dir = member_download_dir + "/uploaded_images"
    # save uploaded_images first ... to adapt the documents image URLs to the local path
    FileUtils::mkdir_p img_download_dir unless Dir.exists? img_download_dir or overwrite

    portfolios_block.css('a.outer-link').each do |a|
      #todo: load JSON and read saved views for members
      portfolio_name = a.text.strip
      include_portfolio = get_parameter_from_option_or_ask(options[:analyze_all], "\t Include Portfolio \'" + portfolio_name + "\'? ", "y") == "y"
      if include_portfolio
        member.portfolios << portfolio_name
        portfolio_view = mahara_accessor.get_portfolio_view member, portfolio_name, a['href']
        portfolio_views << portfolio_view

        # localy save the portfolio for possible further processing
        say "saving view '#{portfolio_view.title}' for member #{member.name} ..."
        view_download_path = views_download_dir + "/" + "view#{i}.html"

        handle_view_images(img_download_dir, mahara_accessor, portfolio_view)

        # now saving view
        portfolio_view.save mahara_accessor.agent, view_download_path
        # instead, we should do something like:
        # save nokogiri_doc.to_html
        # since the Mechanize based save method of the portfolio view does not recognize changes
        # made on the nokogiti doc level ...

        # add to Solr
        add_to_solr(member, portfolio_view, solr)

        # check for further views attached to this one
        if mahara_accessor.has_more_views? portfolio_view then
          say "processing additional views found for view '#{portfolio_view.title}' for user '#{member.name}'"
          mahara_accessor.subsequent_views(portfolio_view).each do |link|
            puts "processing view #{link}"
            next_portfolio_view = mahara_accessor.get_portfolio_view(member, portfolio_view.portfolio_title + " - View 2", link)

            portfolio_views << next_portfolio_view

            # localy save the portfolio for possible further processing
            say "saving view '#{next_portfolio_view.title}' for member #{member.name} ..."
            i = i + 1
            view_download_path = views_download_dir + "/" + "view#{i}.html"

            handle_view_images(img_download_dir, mahara_accessor, next_portfolio_view)

            # now saving view
            next_portfolio_view.save mahara_accessor.agent, view_download_path

            # add to Solr
            add_to_solr(member, next_portfolio_view, solr)
          end
        end

        i = i + 1
      end
      member.views = portfolio_views
      member.save member_download_dir
      end
  end

  # create CSV table summarizing everything we found so far
  csv_summary_filename = group_download_dir + "/" + CSV_SUMMARY_FILE_NAME
  begin
    CSV.open(csv_summary_filename, "wb", {:col_sep => ";"}) do |csv|
      csv << ["Nummer", "Name", "# Views"]
      i = 1
      group_members.each do |member|
        csv << [i, member.name, member.views.length]
        i = i + 1
      end
    end
  rescue Exception => e
    say "ERROR: could not write CSV summary file to '#{csv_summary_filename}'"
  end

  puts "done"

end