#
# Project: PortfolioAnalyzer
# File: group_analyzer.rb
#
# Description:
# GroupAnalyzer class, providing analysis and access to Mahara groups
#
# Author(s):
# Wolfgang Mueller, Univ. of Education Weingarten, MEVIS (mueller@md-phw.de)
#
# (c) Univ. of Education Weingarten, MEVIS, 2016
#

require 'openssl'
I_KNOW_THAT_OPENSSL_VERIFY_PEER_EQUALS_VERIFY_NONE_IS_WRONG = nil
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

require 'mechanize'

MOOPAED_LOGIN_PAGE = 'https://www.moopaed.de/moodle/login/index.php'

MAHARA_DASHBOARD_PAGE = 'https://www.moopaed.de/moodle/auth/mnet/jump.php?hostid=3'

class GroupAnalyzer
  attr_reader :agent, :mahara_dashboard_page

  def initialize( username, password)
    @username = username
    @password = password
    @agent = Mechanize.new()
    @mahara_dashboard_page = nil
  end

  def open_mahara
    # open moodle
    signin_page = @agent.get(MOOPAED_LOGIN_PAGE)
    my_moodle_dashboard_page = signin_page.form_with(:id => 'login') do |form|
      form.username = @username
      form.password = @password
    end.submit

    # now try to access the mahara page directly ... seems much easier than following
    # the link on the page ...
    @mahara_dashboard_page = @agent.get(MAHARA_DASHBOARD_PAGE)

    return @mahara_dashboard_page
  end

  def extract_group_links
    # this one works to extract the group node container:
    # group_list_node = mahara_dashboard_page.css('#groups').each do |node|
    # ...
    # end

    return @mahara_dashboard_page.links_with(:href => /mahara\/group\/view/)

  end
end