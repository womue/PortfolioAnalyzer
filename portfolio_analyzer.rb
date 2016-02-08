#
# Project: PortfolioAnalyzer
# File: reference_analyzer.rb
#
# Description:
# PortfolioAnalyzer main file. Contains general functionalities.
#
# Author(s):
# Wolfgang Mueller, Univ. of Education Weingarten, MEVIS (mueller@md-phw.de)
#
# (c) Univ. of Education Weingarten, MEVIS, 2016
#
# Usage:
#

require 'rubygems'
require 'fileutils'
require 'highline/import'

require_relative 'mahara_accessor'
require_relative 'mahara_member'

MOOPAED_LOGIN_URL = 'https://www.moopaed.de/moodle/login/index.php'
MAHARA_DASHBOARD_URL = 'https://www.moopaed.de/moodle/auth/mnet/jump.php?hostid=3'

DEFAULT_PORTFOLIO_DOWNLOAD_DIR = "#{Dir.home}/MaharaPortfolios"

module PortfolioAnalyzer

  def self.select_group_old(group_links)
    groupid = 0
    loop do
      puts "Available groups:"
      group_links.length.times do |i|
        puts "#{i}:" + group_links[i].text
      end
      puts "#{group_links.length}: exit"

      input = ask("Select groupid:  ") { |q| q.echo = true }
      groupid = input.to_i

      break if not (groupid < 0 or groupid > group_links.length)
    end
    return groupid
  end

  def self.select_group(group_names)
    say "Select mahara group for analysis"
    choose do |menu|
      menu.index = :number
      menu.index_suffix = ") "

      menu.prompt = "Select group:  "
      group_names.each do |link|
        menu.choice link do
          return group_names.index(link)
        end
      end
      menu.choice :exit do
        return group_names.length
      end

    end
  end

  def self.select_option(form, field_id, text)
    value = nil
    form.field_with(:id => field_id).options.each { |o| value = o if o.value == text }

    raise ArgumentError, "No option with text '#{text}' in field '#{field_id}'" unless value
    form.field_with(:id => field_id).value = value
  end

  def self.extract_members(group_members, grouplink, groupname, main_column)
    group_members = []
    main_column.css('div.list-group-item').each do |row|
      student = nil
      a = row.css('a')[0]
      link = a['href']
      name = a.text.strip
      img = row.css('img')[0]
      img_src = img['src']
      span = row.css('span')[1]
      if (span.text.to_s.include? 'Teilnehmer') then
        puts "adding " + name + ": " + link + ", src=" + img_src
        member = MaharaMember.new(name, link, groupname, grouplink)
        group_members << member
      end
    end
    group_members
  end

  username = ask("Enter your username:  ") { |q| q.echo = true }
  #password = ask("Enter your password:  ") { |q| q.echo = "*" }        # currently disabled for ussage inside of RubyMine
  password = ask("Enter your password:  ") { |q| q.echo = true }

  mahara_accessor = MaharaAccessor.new(username, password, MOOPAED_LOGIN_URL, MAHARA_DASHBOARD_URL)
  agent = mahara_accessor.agent
  mahara_dashboard_page = mahara_accessor.open_mahara

  if (mahara_dashboard_page == nil) then
    puts "ERROR: unable to access Mahara dashboard page - user credentials possibly wrong!"
    Kernel.exit(1) if (groupid == group_links.length)
  end

  say "Please enter the directory for downloading member portfolios:"
  portfolio_download_dir = ask('> ') { |q| q.default = DEFAULT_PORTFOLIO_DOWNLOAD_DIR }

  FileUtils::mkdir_p portfolio_download_dir unless Dir.exists? portfolio_download_dir

  group_links = mahara_accessor.extract_group_links

  groupid = select_group(group_links)

  Kernel.exit(0) if (groupid == group_links.length)

  groupname = group_links[groupid].text
  grouplink = group_links[groupid].href

  group_download_dir = portfolio_download_dir + "/" + groupname.gsub(/\s/, '_')

  overwrite = false
  if (Dir.exists? group_download_dir) then
    # overwrite = agree("Download dir for Mahara portfolios for group #{groupname} exists! Overwrite data?", true)     # currently disabled for ussage inside of RubyMine
    say "Download dir for Mahara portfolios for group #{groupname} exists! Overwrite data? [y/n]"
    overwrite = gets == "y"
  end

  FileUtils::mkdir_p group_download_dir unless Dir.exists? group_download_dir or overwrite

  # extract members
  # TODO: this should go somewhere to the MaharaAccessor class
  mahara_group_overview_page = agent.get(grouplink)
  puts 'selecting group member page ...'
  mahara_group_members_page_1 = mahara_group_overview_page.link_with(:href => /mahara\/group\/members/).click

  puts "selecting complete view of members ..."
  form = mahara_group_members_page_1.form_with(:class => 'form-pagination js-pagination form-inline pagination-page-limit dropdown')
  select_option(form, 'setlimitselect', '500')
  mahara_group_members_page_2 = form.submit

  ### extract portfolios
  # TODO: the extraction part should go somewhere to the MaharaAccessor class
  group_members = []
  main_column = mahara_group_members_page_2.css('div.main-column')[0]

  #mahara_group_members_page_2.css('div.list-group-item').each do |row|
  group_members = extract_members(group_members, grouplink, groupname, main_column)

  puts "extracted mumber of portfolio users: " + group_members.length.to_s

  # extract view information
  # TODO: the extractio part should go somewhere to the MaharaAccessor class
  group_members.each do |member|
    puts "portfolios for member " + member.name
    mahara_user_views_page = agent.get(member.mainlink)
    # find block containing
    portfolios_block = mahara_user_views_page.css('.bt-myviews')[0]
    #puts portfolios_block.text
    if (portfolios_block == nil) then
      puts "WARNING: portfolio view block '#{member.name}\'s Portfolios' not found on member's dashboard page"
      puts "Unable to extract portfolio view list!"
      next
    end
    portfolio_views = []
    i = 0
    portfolios_block.css('a.outer-link').each do |a|
      portfolio_view = mahara_accessor.get_portfolio_view member, a.text.strip, a['href']
      portfolio_views << portfolio_view

      # in parallel, get access to the corresponding nokogiri node for modification
      mahara_accessor.agent.get('https://yahoo.com')
      nokogiri_doc = mahara_accessor.agent.page.parser

      # localy save the portfolio for possible further processing
      say "saving view '#{portfolio_view.title}' for member #{member.name} ..."

      member_download_dir = group_download_dir + "/" + member.name.gsub(/\s/, '_')
      views_download_dir = member_download_dir + "/views"

      # save uploaded_images first ... to adapt the documents image URLs to the local path
      img_download_dir = member_download_dir + "/uploaded_images"
      FileUtils::mkdir_p img_download_dir unless Dir.exists? img_download_dir or overwrite
      puts "#{portfolio_view.uploaded_images.length} uploaded_images found!"
      portfolio_view.uploaded_images.each do |image|
        basenamematch = /(?<=\?)[A-Za-z0-9=]*/.match(File.basename image.uri.to_s)
        break unless basenamematch != nil
        basename = basenamematch[0]
        image_download_path = img_download_dir + "/" + basename
        say "saving image to #{image_download_path} ..."
        begin
          image.fetch.save image_download_path
        rescue Mechanize::ResponseCodeError => ex
          puts "An error of type #{ex.class} happened, message is #{ex.message}"
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

      # puts doc.to_html


      view_download_path = views_download_dir + "/" + "view#{i}.html"
      i = i + 1
      FileUtils::mkdir_p views_download_dir unless Dir.exists? views_download_dir or overwrite
      say "saving view '#{portfolio_view.title}' to #{view_download_path} ..."
      portfolio_view.save mahara_accessor.agent, view_download_path
    end
    member.views = portfolio_views
  end

  puts "done"

end