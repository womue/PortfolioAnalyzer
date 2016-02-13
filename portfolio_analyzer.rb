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
require 'highline/import'
require 'fastimage'

require_relative 'portfolio_analyzer_tools'
require_relative 'mahara_accessor'
require_relative 'mahara_member'

MOOPAED_LOGIN_URL = 'https://www.moopaed.de/moodle/login/index.php'
MAHARA_DASHBOARD_URL = 'https://www.moopaed.de/moodle/auth/mnet/jump.php?hostid=3'

DEFAULT_PORTFOLIO_DOWNLOAD_DIR = "#{Dir.home}/MaharaPortfolios"

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

  say "Please enter the directory for local member portfolios storage:"
  portfolio_download_dir = ask('> ') { |q| q.default = DEFAULT_PORTFOLIO_DOWNLOAD_DIR }

  FileUtils::mkdir_p portfolio_download_dir unless Dir.exists? portfolio_download_dir

  username = ask("Enter your username:  ") { |q| q.echo = true }
  #password = ask("Enter your password:  ") { |q| q.echo = "*" }        # currently disabled for usage inside of RubyMine
  password = ask("Enter your password:  ") { |q| q.echo = true }

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
    overwrite = gets == "y"
  end

  FileUtils::mkdir_p group_download_dir unless Dir.exists? group_download_dir or overwrite

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

      views_download_dir = member_download_dir + "/views"

      # save uploaded_images first ... to adapt the documents image URLs to the local path
      img_download_dir = member_download_dir + "/uploaded_images"
      FileUtils::mkdir_p img_download_dir unless Dir.exists? img_download_dir or overwrite
      puts "#{portfolio_view.uploaded_images.length} uploaded_images found!"
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

      view_download_path = views_download_dir + "/" + "view#{i}.html"
      i = i + 1
      FileUtils::mkdir_p views_download_dir unless Dir.exists? views_download_dir or overwrite
      say "saving view '#{portfolio_view.title}' to #{view_download_path} ..."
      portfolio_view.save mahara_accessor.agent, view_download_path
      # instead, we should do something like:
      # save nokogiri_doc.to_html
      # since the Mechanize based save method of the portfolio view does not recognize changes
      # made on the nokogiti doc level ...
    end
    member.views = portfolio_views
    member.save member_download_dir
  end

  puts "done"

end