#
# Project: PortfolioAnalyzer
# File: reference_analyzer.rb
#
# Description:
# PortfolioAnalyzer main file. Contains general functionalities.
#
# Author(s):
# Wolfgang Mueller, Univ. of Education Weingarten, MEVIS (mueller@md-phw.de)
#
# (c) Univ. of Education Weingarten, MEVIS, 2016
#
# Usage:
#

require 'rubygems'
require 'highline/import'

require_relative 'mahara_accessor'
require_relative 'mahara_member'

MOOPAED_LOGIN_URL = 'https://www.moopaed.de/moodle/login/index.php'
MAHARA_DASHBOARD_URL = 'https://www.moopaed.de/moodle/auth/mnet/jump.php?hostid=3'

module PortfolioAnalyzer
  username = ask("Enter your username:  ") { |q| q.echo = true }
  #password = ask("Enter your password:  ") { |q| q.echo = "*" }
  password = ask("Enter your password:  ") { |q| q.echo = true }

  group_analyzer = MaharaAccessor.new(username, password, MOOPAED_LOGIN_URL, MAHARA_DASHBOARD_URL)
  agent = group_analyzer.agent
  mahara_dashboard_page = group_analyzer.open_mahara

  group_links = group_analyzer.extract_group_links

  def self.select_option(form, field_id, text)
    value = nil
    form.field_with(:id => field_id).options.each{|o| value = o if o.value == text }

    raise ArgumentError, "No option with text '#{text}' in field '#{field_id}'" unless value
    form.field_with(:id => field_id).value = value
  end

  def self.select_group(group_links)
    groupid = 0
    loop do
      puts "Available groups:"
      group_links.length.times do |i|
        puts "#{i}:" + group_links[i].text
      end
      puts "#{group_links.length}: exit"

      input = ask("Select groupid:  ") { |q| q.echo = true }
      groupid = input.to_i

      break if not (groupid < 0 or groupid > group_links.length)
    end
    return groupid
  end

  groupid = select_group(group_links)
  puts "selected group:" + groupid.to_s

  Kernel.exit(0) if (groupid == group_links.length)

  groupname = group_links[groupid].text
  grouplink = group_links[groupid].href

  # extract members
  mahara_group_overview_page = agent.get(grouplink)
  puts 'selecting group member page ...'
  mahara_group_members_page_1 = mahara_group_overview_page.link_with(:href => /mahara\/group\/members/).click

  puts "selecting complete view of members ..."
  form = mahara_group_members_page_1.form_with(:class => 'form-pagination js-pagination form-inline pagination-page-limit dropdown')
  select_option( form, 'setlimitselect', '500')
  mahara_group_members_page_2 = form.submit

  ### extract portfolios
  group_members = []
  main_column = mahara_group_members_page_2.css('div.main-column')[0]
  #mahara_group_members_page_2.css('div.list-group-item').each do |row|
  main_column.css('div.list-group-item').each do |row|
    student = nil
    a = row.css('a')[0]
    link = a['href']
    name = a.text.strip
    img = row.css('img')[0]
    img_src = img['src']
    span = row.css('span')[1]
    if (span.text.to_s.include? 'Teilnehmer') then
      puts "adding " + name + ": " + link + ", src=" + img_src
      member = MaharaMember.new(name, link, groupname, grouplink)
      group_members << member
    end
  end

  puts "extracted mumber of portfolio users: " + group_members.length.to_s

  # extract view information
  group_members.each do |member|
    puts "portfolios for member " + member.owner_name
    mahara_user_views_page = agent.get(member.mainlink)
    # find block containing
    portfolios_block = mahara_user_views_page.css('.bt-myviews')[0]
    #puts portfolios_block.text
    if (portfolios_block == nil) then
      puts "WARNING: portfolio view block '#{member.owner_name}\'s Portfolios' not found on member's dashboard page"
      puts "Unable to extract portofolio view list!"
      next
    end
    portfolios_block.css('a').each do |a|
      puts a.text.strip + ': ' + a['href']
    end
  end

  puts  "done"

end