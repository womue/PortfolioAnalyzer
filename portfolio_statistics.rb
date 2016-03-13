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

  class TotalWordsCounter < MemberAnalyzer
    def initialize
      @titles = ['# Words']
    end

    def word_count str
      str.tr("'-/–…\.", ' ').split.size
    end

    def get_stats member
      nr_words = 0
      member.views.each do |view|
        nr_words += word_count view.text
      end
      [nr_words]
    end
  end
end