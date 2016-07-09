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
#

require 'rubygems'
require 'fileutils'
require 'optparse'
require 'highline/import'
require 'fastimage'
require 'rsolr'
require 'csv'

require_relative 'portfolio_analyzer/portfolio_analyzer_tools'
require_relative 'portfolio_analyzer/mahara_accessor'
require_relative 'portfolio_analyzer/mahara_member'

DEFAULT_PORTFOLIO_DOWNLOAD_DIR = "#{Dir.home}/MaharaPortfolios"

#INDIVIDUAL_PORTFOLIOS_DIR_NAME = "IndividualPortfolios"
INDIVIDUAL_PORTFOLIOS_CONFIG_FILE_NAME = "IndividualDownloads.config"

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
      # TODO: write manipulated document
      # write HTML to file. Nokogiri provides the updated HTML: nokogiri_doc.to_html
    end
  end

  def self.add_to_solr(member, portfolio_view, solr)
    puts "adding view to Solr ... " unless solr == nil
    puts portfolio_view.to_solr(member)
    begin
      solr.add portfolio_view.to_solr(member) unless solr == nil
    rescue Exception => e
      say "ERROR: " + e.to_s
    end

    # solr.add :id=>1, :price=>1.00 unless solr == nil
    puts "done!" unless solr == nil
  end

  def self.read_user_config(download_dir)
    puts "Reading user config from " + download_dir
    user_names = []
    #individual_download_dir = download_dir + "/" + INDIVIDUAL_PORTFOLIOS_DIR_NAME
    #FileUtils::mkdir_p individual_download_dir

    filename = download_dir + "/" + INDIVIDUAL_PORTFOLIOS_CONFIG_FILE_NAME

    begin
      file = nil
      if not File.exists? filename
        puts "Creating " + filename
        file = File.open(filename, 'w')
      else
        file = File.new(filename, "r")
        while (line = file.gets)
          user_names << line
        end
      end
      file.close
    rescue => err
      puts "Could not access user config file: #{err}"
    end
    user_names
  end

end