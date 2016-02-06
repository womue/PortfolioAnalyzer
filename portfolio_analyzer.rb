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

require_relative 'group_analyzer'
require_relative 'student_portfolio'

module PortfolioAnalyzer
  username = ask("Enter your username:  ") { |q| q.echo = true }
  #password = ask("Enter your password:  ") { |q| q.echo = "*" }
  password = ask("Enter your password:  ") { |q| q.echo = true }

  group_analyzer = GroupAnalyzer.new(username, password)
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

  # we might have to submit here ...

  ### extract portfolios
  portfolios = []
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
      # puts "adding " + name + ": " + link + ", src=" + img_src
      student = StudentPortfolio.new(name, link, groupname, grouplink)
      portfolios << student
    end
  end

  puts "extracted mumber of portfolio users: " + portfolios.length.to_s

  # extract view information
  portfolios.each do |p|
    mahara_user_views_page = agent.get(p.mainlink)

  end

  puts  "done"

end