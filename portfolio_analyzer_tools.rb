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
end