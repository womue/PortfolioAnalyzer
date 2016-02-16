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

require 'json'

require_relative 'jsonable'

class MaharaMember < Jsonable
  attr_accessor :name, :mainlink, :groupid, :grouplink, :portfolios, :views

  SERIALIZATION_FILE_NAME = 'memberinfo.json'

  # construct a new instance
  # params
  # - name: name of the member
  # - mainlink: link to the member's external main page
  # - groupid; group id the user is connected to
  # - grouplink: link of the group's dashboard page, collecting all information on the group members
  def initialize(name=nil, mainlink=nil, groupid=nil, grouplink=nil)
    @name = name
    @mainlink = mainlink
    @groupid = groupid
    @grouplink = grouplink
    @portfolios = []
    @views = []
  end

  def save dir
    filename = dir + "/" + SERIALIZATION_FILE_NAME
    File.open(filename, 'w') { |file| file.write(self.to_json) }
  end

  def self.load dir
    filename = dir + "/" + SERIALIZATION_FILE_NAME
    s = File.open(filename, 'r') { |file| file.read }
    member = MaharaMember.new
    member.from_json! s
    member
  end
end