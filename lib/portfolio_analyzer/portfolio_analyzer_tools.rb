#
# Project: PortfolioAnalyzer
# File: portfolio_analyzer_tools.rb
#
# Description:
# PortfolioAnalyzer tools.
#
# Author(s):
# Wolfgang Mueller, Univ. of Education Weingarten, MEVIS (mueller@md-phw.de)
#
# (c) Univ. of Education Weingarten, MEVIS, 2016
#

require 'solid_assert'
SolidAssert.enable_assertions

module PortfolioAnalyzerTools
  # selects the specified option in a mechanize page form
  # - form: the form in which the option is to be selected
  # - field_id: the id of the field where the selection shall be performed
  # - text: text specifying the option to select
  def self.select_option(form, field_id, text)
    value = nil
    form.field_with(:id => field_id).options.each { |o| value = o if o.value == text }

    raise ArgumentError, "No option with text '#{text}' in field '#{field_id}'" unless value
    form.field_with(:id => field_id).value = value
  end

  # displays a menu to the user to select from a list of Mahara member groups
  # params:
  # - group_names: an Array containing the possible selections
  def self.select_choice(msg, choices)
    say msg
    choose do |menu|
      menu.index = :number
      menu.index_suffix = ") "

      menu.prompt = "Select choice:  "
      choices.each do |ch|
        menu.choice ch do
          return choices.index(ch)
        end
      end
      menu.choice :exit do
        return choices.length
      end

    end
  end

  # saves a nokokiri html doc under the specified path
  # - nokogiri_doc: the nokogiri doc
  # - path: the path
  def self.save_nokogiri_doc(nokogiri_doc, path)
    assert(nokogiri_doc != nil)
    say "saving nokogiri doc #{nokogiri_doc.name} to #{path} ..."
    # nokogiri_doc.write_html_to path
    File.write(path, nokogiri_doc.to_html)
  end
end

class String
  # File activesupport/lib/active_support/core_ext/string/filters.rb, line 16
  def squish!
    gsub!(/\A[[:space:]]+/, '')
    gsub!(/[[:space:]]+\z/, '')
    gsub!(/[[:space:]]+/, ' ')
    self
  end
end