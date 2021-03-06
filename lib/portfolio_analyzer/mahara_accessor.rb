#
# Project: PortfolioAnalyzer
# File: mahara_accessor.rb
#
# Description:
# MaharaAccessor class, providing access to Mahara groups and bundling the
# webscraping functionality required to extract information from mahara group member pages.
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

require_relative 'portfolio_analyzer_tools'
require_relative 'portfolio_view'
require_relative 'mahara_member'

class MaharaAccessor
  include Logging
  attr_reader :agent, :moodle_login_url, :mahara_dahboard_url, :mahara_dashboard_page

  # Constructs a MaharaAccessor.
  # - username: id of the user for logging in into the service
  # - password: password of the user
  # - login_url: moodle login page
  # - mahara_dashboard_url: url for the mahara dashboard page to use
  def initialize(username, password, login_url, mahara_dashboard_url)
    @username = username
    @password = password
    @agent = Mechanize.new()
    @moodle_login_url = login_url
    @mahara_dahboard_url = mahara_dashboard_url
    @mahara_dashboard_page = nil
  end

  # Connects to moodle using the provided credentials and open the corresponding user's Mahara dashboard page.
  def open_mahara
    # open moodle url which redirects to shibboleth service
    signin_page = @agent.get(@moodle_login_url)

    # Fill in shibboleth login form
    form = signin_page.forms[0]
    form.field_with(:id => "username").value = @username
    form.field_with(:id => "password").value = @password
    javascript_warning_page = form.click_button

    # The login system wants a confirmation: 
    # Since your browser (mechanize) does not support JavaScript, you must press the Continue button once to proceed. 
    form = javascript_warning_page.forms[0]
    my_moodle_dashboard_page = form.submit

    # now try to access the mahara page directly ... seems much easier than following
    # the link on the page ...
    @mahara_dashboard_page = @agent.get(@mahara_dahboard_url)

    return @mahara_dashboard_page
  end

  # Extracts the group links for Mahara groups from a user's Mahara dashboard page
  def extract_group_links
    # this one works to extract the group node container:
    #
    # group_list_node = mahara_dashboard_page.css('#groups').each do |node|
    # ...
    # end
    #
    # However, I decided to go the easy way here with some knowledge on how the url must look like

    return @mahara_dashboard_page.links_with(:href => /mahara\/group\/view/)
  end

  # Extracts a portfolio view page.
  # Params:
  # - member: name of the corresponding Mahara member
  # - url: the internal Mahara url to the corresponding page
  #
  # @param [MaharaMember] member
  # @param [String] portfolio_name
  # @param [String] url
  def get_portfolio_view member, portfolio_name, url
    view_page = @agent.get(url)

    modified_date = @agent.get(url).response["last-modified"]

    # Try to extract the view title. That is, we are checking for an h1 tag ...
    view_title = guess_title(view_page)

    view = PortfolioView.new url, view_page, member.name, portfolio_name, view_title, member.groupid, modified_date
    return view
  end

  # Guesses the title from a view page
  # params:
  # - view_page: the Mahara view page
  def guess_title(view_page)
    title = "unknown"
    h1 = view_page.css('h1')
    if (h1 != nil)
      title = view_page.title
    else
      title = h1.text
    end
    title
  end

  def has_more_views?(view_page)
    nodes = view_page.page.css('nav.custom-dropdown')
    (nodes != nil) && (nodes.length !=0)
  end

  def subsequent_views(view_page)
    view_selector_node = view_page.page.css('nav.custom-dropdown')[0]
    view_link_nodes = view_selector_node.css('a')
    links = []
    view_link_nodes.each do |node|
      link = node['href']
      links << link unless link == view_page.url
    end
    links
  end

  # extracts all members from the main column of a Mahara groups or find contacts page
  # params:
  # - main_column: the main column
  # - grouplink: the link to the corresponding group to be passed to the members to be created
  # - groupname: the name to the corresponding group to be passed to the members to be created
  # - is_group_search: true, if members from a group are extracted; false, if individual members are extracted
  def extract_members(main_column, grouplink, groupname, is_group_search=true)
    group_members = []
    main_column.css('div.list-group-item').each do |row|
      student = nil
      a = row.css('a')[0]
      link = a['href']
      name = a.text.strip
      img = row.css('img')[0]
      img_src = img['src']
      span = row.css('span')[1]
      if (span.text.to_s.include? 'Teilnehmer' or not is_group_search) then
        puts "adding " + name + ": " + link + ", src=" + img_src
        member = MaharaMember.new(name, link, groupname, grouplink)
        group_members << member
      end
    end
    group_members
  end

  def html
    @page
  end

  # Extracts the group members from a Mahara group page
  # params:
  # - grouplink: link to the corresponding Mahara group page
  # - groupname: the id of this group
  def extract_group_members(grouplink, groupname)
    mahara_group_overview_page = @agent.get(grouplink)
    # selecting group member page ...
    mahara_group_members_page_1 = mahara_group_overview_page.link_with(:href => /mahara\/group\/members/).click
    # selecting complete view of members
    form = mahara_group_members_page_1.form_with(:class => 'form-pagination js-pagination form-inline pagination-page-limit dropdown')
    PortfolioAnalyzerTools.select_option(form, 'setlimitselect', '500')
    mahara_group_members_page_2 = form.submit

    # extract members
    main_column = mahara_group_members_page_2.css('div.main-column')[0]
    # an alternative, more general approach might be: mahara_group_members_page_2.css('div.list-group-item').each do |row|

    group_members = extract_members(main_column, grouplink, groupname)
  end

  # Performs a user search using the user query input field.
  # Returns a list of MaharaMember objects
  # - username: name of the user
  def find_user(username)
    user_search_form = @mahara_dashboard_page.form_with(:id => 'usf')
    user_search_form.field_with(:name => "query").value = username
    find_contacts_page = user_search_form.submit
    # extract all users from the search result list
    friendslist = find_contacts_page.at('#friendslist')
    users = extract_members(friendslist, nil, 'individual', false)
  end
end