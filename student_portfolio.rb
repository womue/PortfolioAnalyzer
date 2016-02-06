#
# Project: PortfolioAnalyzer
# File: StudentPortfolio
#
# Description:
# 
#
# Author(s):
# Wolfgang Mueller, Univ. of Education Weingarten, MEVIS (mueller@md-phw.de)
#
# (c) Univ. of Education Weingarten, MEVIS, 2016
#

class StudentPortfolio
  attr_reader :owner_name, :mainlink, :groupid, :grouplink
  attr_accessor :pages

  def initialize( name, mainlink, groupid, grouplink)
    @owner_name = name
    @mainlink = mainlink
    @groupid = groupid
    @grouplink = grouplink
    @pages = []
  end

end