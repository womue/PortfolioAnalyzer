#
# Project: PortfolioAnalyzer
# File: mahara_accessor.rb
#
# Description:
# MaharaAccessor class, providing access to Mahara groups and bundling the
# webscrapting functionality required to extract information from mahara group member pages.
# This file might have to be mostly rewritten to provide Mahara access for a specific
# Mahara service.
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

class MaharaAccessor
  attr_reader :agent, :moodle_login_url, :mahara_dahboard_url, :mahara_dashboard_page

  def initialize(username, password, login_url, mahara_dashboard_url)
    @username = username
    @password = password
    @agent = Mechanize.new()
    @moodle_login_url = login_url
    @mahara_dahboard_url = mahara_dashboard_url
    @mahara_dashboard_page = nil
  end

  def open_mahara
    # open moodle
    signin_page = @agent.get(@moodle_login_url)
    my_moodle_dashboard_page = signin_page.form_with(:id => 'login') do |form|
      form.username = @username
      form.password = @password
    end.submit

    # now try to access the mahara page directly ... seems much easier than following
    # the link on the page ...
    @mahara_dashboard_page = @agent.get(@mahara_dahboard_url)

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