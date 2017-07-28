#
# Project: PortfolioAnalyzer
# File: portfolio_analyzer_tools.rb
#
# Description:
# PortfolioAnalyzer statistics.
#
# Author(s):
# Wolfgang Mueller, Univ. of Education Weingarten, MEVIS (mueller@md-phw.de)
#
# (c) Univ. of Education Weingarten, MEVIS, 2016
#
require 'csv'
require 'mechanize'
require 'words_counted'

require_relative 'mahara_member'
require_relative 'portfolio_view'

module PortfolioStatistics
  class AbstractClassInstiationError < RuntimeError;
  end

  class AbstractMethodInvocationError < RuntimeError;
  end

  class ViewAnalyzer

    # @return [PortfolioStatistics]
    def initialize
      raise AbstractClassInstiationError, "Cannot instantiate this class directly"
    end

    def get_column_titles
      return @titles
    end


    # @param [PortfolioView] view
    def get_stats view
      raise AbstractMethodInvocationError, "Abstract method invocated: implementation missing"
    end
  end

  # @attr [ViewAnalyzer] view_analyzer
  class MemberAnalyzer
    attr_accessor :view_analyzer

    def initialize view_analyzer
      @view_analyzer = view_analyzer
    end

    # returns all available stats
    # @param [Mahara_Member] member
    # @return [Array]
    def get_stats member
      stats = @view_analyzer.get_stats member.views.first
      member.views[1, view.length].each do |view|
        new_stats = []
        stats.zip(@view_analyzer.get_stats view) {|x, y| new_stats << x + y}
        stats = new_stats
      end
      return stats
    end
  end

  class DescriptiveViewAnalyzer < ViewAnalyzer
    def initialize
      @titles = [:nrWords => '# Words', :nrExternalLinks => '# Ext.Refs', :nrImages => '# Images', :nrUploadedImages => '# Image artefacts',
                 :nrWikipediaImages => '# Wikipedia images', :nrInstagramImages => '# Instagram images', :nrFlickrImages => '# Flickr images',
                 :nrSnapchatImages => '# Snapchat images', :nrPinterestImages => '# Pinterest images']
    end

    # Returns nr of words
    # @param [PortfolioView] view
    # @return [Integer]
    def word_count view
      # counter = WordsCounted::Counter.new view.text
      # return counter.word_count
      return view.text.tr("'-/–…\.", ' ').split.size
    end

    # Returns all external links
    # @param [PortfolioView] view
    # @return [Array]
    def external_links view
      all_links = view.page.links_with(:href => /http/)

      internal_links = view.page.links_with(:href => /mahara/)
      internal_links += view.page.links_with(:href => /^\.\./)

      return all_links - internal_links
    end

    # Returns all images (also images provided by mahara: e.g. emoticons)
    # @param [PortfolioView] view
    # @return [Array]
    def images view
      # puts page.css('img')
      return view.page.css('img')
    end

    # Returns uploaded image artefacts
    # @param [PortfolioView] view
    # @return [Array]
    def uploaded_images view
      # this is for uploaded artefacts in mahara
      # artefact_images = view.page.css("img[src*='www.moopaed.de\/mahara\/artefact']")
      # this is for local analysis
      # artefact_images = view.page.css("img[src*='uploaded_images']")
      artefact_images = view.page.images_with(src: /www.moopaed.de\/mahara\/artefact/)
      return artefact_images
    end


    # Returns number of linked image artefacts from a specific domain
    # @param [PortfolioView] view
    # @param [String] domain
    # @return [Array]
    def images_from_domain view, domain
      # this is for uploaded artefacts in mahara
      artefact_images = view.page.css("img[src*='#{domain}']")
      return artefact_images
    end

    # Returns all available stats as a hash
    # @param [PortfolioView] view
    def get_stats view
      res = Hash.new
      res[:nrWords] = word_count(view)
      res[:nrExternalLinks] = external_links(view)
      res[:nrImages] = images(view).size
      res[:nrUploadedImages] = uploaded_images(view).size
      res[:nrWikipediaImages] = images_from_domain(view, 'wikipedia').size
      res[:nrInstagramImages] = images_from_domain(view, 'instagram').size
      res[:nrFlickrImages] = images_from_domain(view, 'flickr').size
      res[:nrSnapchatImages] = images_from_domain(view, 'snapchat').size
      res[:nrPinterestImages] = images_from_domain(view, 'pinterest').size
      return res
    end
  end

  class OutlineAnalyzer < DescriptiveViewAnalyzer
    # @param [MaharaMember] page
    # @deprecated
    def get_view_stats member
      table_titles = ['Title'] + @titles
      stats_table = [table_titles]
      member.views.each do |view|
        title = view.page.css('h1').first.text.strip
        nr_words = word_count view.page
        nr_imgs = all_images_count view.page
        nr_img_artefacts = artefact_images_count view.page
        nr_refs = external_links(view.page).size
        stats_table << [title, nr_words, nr_imgs, nr_img_artefacts, nr_refs]
      end
      stats_table
    end

    # @param [MaharaMember] member
    # @deprecated
    def get_outline member
      stats_table = [['Portfolio outline']]
      member.views.each do |view|
        title = view.page.css('h1').first.text.strip
        stats_table << [title]
        # Heading tags to extract
        heading_tags = ['h3']
        prefix = '  ** '
        heading_tags.each do |tag|
          nodes = view.page.css(tag)
          nodes.each do |node|
            title = prefix + node.text.strip
            stats_table << [title]
          end
          prefix = '  ' + prefix
        end

      end
      stats_table
    end

    # @param [MaharaMember] member
    # @deprecated
    def external_links_list member
      links_list = [['External links']]
      member.views.each do |view|

        external_links(view.page).each do |ref|
          links_list << [ref]
        end
      end
      links_list
    end
  end
end