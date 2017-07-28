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
  attr_accessor :name, :mainlink, :groupid, :grouplink, :portfolios, :views, :local_dir

  SERIALIZATION_FILE_NAME = 'memberinfo.json'

  # construct a new instance
  # params
  # - name: name of the member
  # - mainlink: link to the member's external main page
  # - groupid; group id the user is connected to
  # - grouplink: link of the group's dashboard page, collecting all information on the group members
  # @attr [String] name
  # @attr [Array] portfolios
  # @attr [Array] views
  def initialize(name=nil, mainlink=nil, groupid=nil, grouplink=nil)
    @name = name
    @mainlink = mainlink
    @groupid = groupid
    @grouplink = grouplink
    @portfolios = []
    @views = []
    @local_dir = nil
  end

  def save dir
    filename = dir + "/" + SERIALIZATION_FILE_NAME
    File.open(filename, 'w') { |file| file.write(self.to_json) }
  end

  def self.load dir
    filename = dir + "/" + SERIALIZATION_FILE_NAME
    json_s = File.open(filename, 'r') { |file| file.read }
    # old approach
    # member = MaharaMember.new
    # member.from_json! json_s
    # member = json_create json_s
    member = JSON.load(json_s)
    member.local_dir = dir
    # reconstruct views
    member
  end

  def to_s
    return "Member-Name: " + @name + "; mainlink: " + @mainlink + "; #Portfolios: " + @portfolios.length.to_s + "; #Views: " + @views.length.to_s
  end
end