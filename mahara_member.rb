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
  attr_accessor :views

  # construct a new instance
  # params
  # - name: name of the member
  # - mainlink: link to the member's external main page
  # - groupid; group id the user is connected to
  # - grouplink: link of the group's dashboard page, collecting all information on the group members
  def initialize( name, mainlink, groupid, grouplink)
    @name = name
    @mainlink = mainlink
    @groupid = groupid
    @grouplink = grouplink
    @views = []
  end

end