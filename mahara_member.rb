#
# Project: PortfolioAnalyzer
# File: MaharaMember
#
# Description:
# 
#
# Author(s):
# Wolfgang Mueller, Univ. of Education Weingarten, MEVIS (mueller@md-phw.de)
#
# (c) Univ. of Education Weingarten, MEVIS, 2016
#

class MaharaMember
  attr_reader :name, :mainlink, :groupid, :grouplink
  attr_accessor :pages

  def initialize( name, mainlink, groupid, grouplink)
    @name = name
    @mainlink = mainlink
    @groupid = groupid
    @grouplink = grouplink
    @pages = []
  end

end