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
require_relative 'mahara_member'

module PortfolioStatistics
  class MemberAnalyzer
    class AbstractClassInstiationError < RuntimeError;
    end
    class AbstractMethodInvocationError < RuntimeError;
    end

    def initialize
      raise AbstractClassInstiationError, "Cannot instantiate this class directly"
    end

    def get_column_titles
      return @titles
    end

    def get_stats member
      raise AbstractMethodInvocationError, "Abstract method invocated: implementation missing"
    end
  end

  class DescriptiveAnalyzer < MemberAnalyzer
    def initialize
      @titles = ['# Words', '# Images', '# Image artefacts', '# Ext.Refs']
    end

    def word_count str
      str.tr("'-/–…\.", ' ').split.size
    end

    # Extracts the external links included on the given page
    def external_links page
      all_links = page.links

      internal_links = page.links_with(:href => /mahara/)
      internal_links += page.links_with(:href => /#/)
      internal_links += page.links_with(:href => "")

      return all_links - internal_links
    end

    # Counts all images (also images provided by mahara: e.g. emoticons)
    def all_images_count page
      # puts page.css('img')
      return page.css('img').size
    end

    # Only counts uploaded image artefacts
    def artefact_images_count page
      # this is for uploaded artefacts in mahara
      # artefact_images = page.css("img[src*='www.moopaed.de\/mahara\/artefact']")
      # this is for local analysis
      artefact_images = page.css("img[src*='uploaded_images']")
      return artefact_images.size
    end

    def get_stats member
      nr_words = 0
      nr_imgs  = 0
      nr_img_artefacts = 0
      nr_refs  = 0
      member.views.each do |view|
        nr_words += word_count view.text
        # Count
        nr_imgs  += all_images_count view.page
        nr_img_artefacts += artefact_images_count view.page
        puts external_links(view.page)
        nr_refs += external_links(view.page).size
      end
      [nr_words, nr_imgs, nr_img_artefacts, nr_refs]
    end
  end


  class OutlineAnalyzer < DescriptiveAnalyzer

    def get_view_stats member
      table_titles = ['Title'] + @titles
      stats_table = [table_titles]
      member.views.each do |view|
        title = view.page.css('h1').first.text.strip
        nr_words = word_count view.text
        nr_imgs = all_images_count view.page
        nr_img_artefacts = artefact_images_count view.page
        nr_refs = external_links(view.page).size
        stats_table << [title, nr_words, nr_imgs, nr_img_artefacts, nr_refs]
      end
      stats_table
    end

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