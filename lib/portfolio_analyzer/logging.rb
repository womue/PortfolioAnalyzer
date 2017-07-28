#
# Project: PortfolioAnalyzer
# File: logging.rb
#
# Description: generic logging support for sub classes.
# Approach was taken from: http://stackoverflow.com/questions/917566/ruby-share-logger-instance-among-module-classes
#
#
# Author(s):
# Wolfgang Mueller, Univ. of Education Weingarten, MEVIS (mueller@md-phw.de)
#
# (c) Univ. of Education Weingarten, MEVIS, 2016
#
require 'logger'

module Logging
  class << self
    def logger
      @logger ||= Logger.new($stdout)
    end

    def logger=(logger)
      @logger = logger
    end
  end

  # Addition
  def self.included(base)
    class << base
      def logger
        Logging.logger
      end
    end
  end

  def logger
    self.class.logger
  end
end
