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

require 'bundler/setup'
require 'rubygems'
require 'fileutils'
require 'optparse'
require 'highline/import'
require 'fastimage'
require 'rsolr'
require 'csv'

#require_relative 'lib/portfolio_analyzer/portfolio_analyzer_tools'
#require 'portfolio_analyzer/portfolio_analyzer_tools'
#require_relative 'lib/portfolio_analyzer/mahara_accessor'
#require 'portfolio_analyzer/mahara_accessor'
#require_relative 'lib/portfolio_analyzer/mahara_member'
#require 'portfolio_analyzer/mahara_member'
require 'portfolio_analyzer'

MOOPAED_LOGIN_URL = 'https://www.moopaed.de/moodle/login/index.php'
MAHARA_DASHBOARD_URL = 'https://www.moopaed.de/moodle/auth/mnet/jump.php?hostid=3'


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
    opt.on('-r', '--download_images') { |o| options[:download_images] = "y" }
    opt.on('-o', '--only_individual_portfolios') { |o| options[:only_individual_portfolios] = "y" }
  end.parse!

portfolio_download_dir = PortfolioAnalyzer.get_parameter_from_option_or_ask(options[:local_dir], "Please enter the directory for local member portfolios storage:", DEFAULT_PORTFOLIO_DOWNLOAD_DIR)
  say "using portfolio download dir '#{portfolio_download_dir}'"

  FileUtils::mkdir_p portfolio_download_dir unless Dir.exists? portfolio_download_dir

username = PortfolioAnalyzer.get_parameter_from_option_or_ask(options[:username], "Enter your username:  ")
  say "using username '#{username}'"

  # password = get_parameter_from_option_or_ask( options[:password], "Enter your password:  ", nil, "*")    # currently disabled for usage inside of RubyMine
password = PortfolioAnalyzer.get_parameter_from_option_or_ask(options[:password], "Enter your password:  ", nil, true)

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

download_images = PortfolioAnalyzer.get_parameter_from_option_or_ask(options[:download_images], "Download uploaded view images? : ", "n") == "y"
  say "downloading view images ..." if download_images

  overwrite = false
  if (Dir.exists? group_download_dir) then
    # overwrite = agree("Download dir for Mahara portfolios for group #{groupname} exists! Overwrite data?", true)     # currently disabled for ussage inside of RubyMine
    say "Download dir for Mahara portfolios for group #{groupname} exists! Overwrite data? [y/n]"
    overwrite = ask('> ') { |q| q.default = 'y' } == 'y'

    if (!overwrite) then
      i = 1
      new_download_dir = group_download_dir + ".#{i}"
      while (Dir.exists? new_download_dir)
        i = i + 1
        new_download_dir = group_download_dir + ".#{i}"
      end
      group_download_dir = new_download_dir
    end
  end

  # FileUtils::mkdir_p group_download_dir unless Dir.exists? group_download_dir or overwrite
  FileUtils::mkdir_p group_download_dir

  # say "Add views to Solr?:"
  # add_to_solr = ask('> ') { |q| q.default = 'y' } == 'y'
add_to_solr = PortfolioAnalyzer.get_parameter_from_option_or_ask(options[:use_solr], "Add views to Solr?: ", "n") == "y"
  say "adding documents to solr" if add_to_solr

  solr_url = nil
solr_url = PortfolioAnalyzer.get_parameter_from_option_or_ask(options[:solr_url], "Enter Solr URL: ", DEFAULT_SOLR_URL) if add_to_solr
  say "using solr server at '#{solr_url}'" if add_to_solr

  solr = nil
  solr = RSolr.connect :url => solr_url if (add_to_solr)
  if (solr == nil) and (add_to_solr) then
    say "warning: connection to Solr could not be established!"
  end

  group_members = []

only_individual_portfolios = PortfolioAnalyzer.get_parameter_from_option_or_ask(options[:only_individual_portfolios], "Only load individual portfolios?: ", "n") == "y"
  say "downloading individual portfolios" if only_individual_portfolios

  if not only_individual_portfolios
    # extract members
    group_members = mahara_accessor.extract_group_members(grouplink, groupname)
    puts "extracted mumber of portfolio users: " + group_members.length.to_s
  end
PortfolioAnalyzer.read_user_config(group_download_dir).each do |user|
    group_members.concat mahara_accessor.find_user(user)
  end

  # extract view information
  # TODO: the extract part should go somewhere to the MaharaAccessor class
  updated_members = []
  group_members.each do |member|
    puts "portfolios for member " + member.name
    config_available = false

    member_download_dir = group_download_dir + "/" + member.name.gsub(/\s/, '_')
    # create member download dir if necessary
    if (not Dir.exist? member_download_dir) then
      begin
        Dir.mkdir member_download_dir
      rescue Exception => e
        say "error creating download dir for member " + member.name + ": " + e.to_s
        next
      end
    elsif options[:analyze_all] != "y"
      # try to restore member state from JSON file
      begin
        member = MaharaMember.load(member_download_dir)
        say "Restored member " + member.name
        config_available = true unless member.portfolios == nil or member.portfolios.empty?
      rescue Exception => e
        say "Could not restore member " + member.name + ": " + e.to_s
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
      portfolio_name = a.text.strip
      include_portfolio = false
      # use existing configuration if available
      if config_available
        include_portfolio = member.portfolios.include?(portfolio_name)
      else
        include_portfolio = PortfolioAnalyzer.get_parameter_from_option_or_ask(options[:analyze_all], "\t Include Portfolio \'" + portfolio_name + "\'? ", "y") == "y"
        # update member settings depending on user input
        member.portfolios << portfolio_name if include_portfolio
      end

      if include_portfolio
        portfolio_view = mahara_accessor.get_portfolio_view member, portfolio_name, a['href']
        portfolio_views << portfolio_view

        # locally save the portfolio for possible further processing
        say "saving view '#{portfolio_view.title}' for member #{member.name} ..."
        view_download_path = views_download_dir + "/" + "view#{i}.html"
        modified_view_download_path = views_download_dir + "/" + "view#{i}-modified.html"

        relative_path = Pathname.new(img_download_dir).relative_path_from(Pathname.new(views_download_dir)).to_path
        modified_doc = PortfolioAnalyzer.handle_view_images(relative_path, mahara_accessor, portfolio_view) if download_images

        # now saving view
        portfolio_view.save mahara_accessor.agent, view_download_path

        # saving modified view with adapted image paths
        # this has to be done with the nokogiri-based document object since
        # the Mechanize based save method of the portfolio view does not recognize changes
        # made on the nokogiri doc level ...
        PortfolioAnalyzerTools.save_nokogiri_doc( modified_doc, modified_view_download_path) if modified_doc != nil
        
        # add to Solr
        PortfolioAnalyzer.add_to_solr(member, portfolio_view, solr)

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

            # PortfolioAnalyzer.handle_view_images(img_download_dir, mahara_accessor, next_portfolio_view) if download_images
            relative_path = Pathname.new(img_download_dir).relative_path_from(Pathname.new(views_download_dir))  .to_path
            PortfolioAnalyzer.handle_view_images(relative_path, mahara_accessor, next_portfolio_view) if download_images

            # now saving view
            next_portfolio_view.save mahara_accessor.agent, view_download_path

            # add to Solr
            PortfolioAnalyzer.add_to_solr(member, next_portfolio_view, solr)
          end
        end

        i = i + 1
      end
    end

    member.views = portfolio_views
    member.save member_download_dir
    updated_members << member
    #end
  end

  # create CSV table summarizing everything we found so far
  csv_summary_filename = group_download_dir + "/" + CSV_SUMMARY_FILE_NAME
  begin
    CSV.open(csv_summary_filename, "wb", {:col_sep => ";"}) do |csv|
      csv << ["Nummer", "Name", "# Views"]
      i = 1
      updated_members.each do |member|
        puts member
        csv << [i, member.name, member.views.length]
        i = i + 1
      end
    end
  rescue Exception => e
    say "ERROR: could not write CSV summary file to '#{csv_summary_filename}'"
  end

  puts "done"
