#
# Project: portfolio_anaylzer
# File: JSONeable
#
# Description:
# Provides a base class for JSON serialization. This approach follows
# http://stackoverflow.com/questions/4464050/ruby-objects-and-json-serialization-without-rails
#
# Author(s):
# Wolfgang Mueller, Univ. of Education Weingarten, MEVIS (mueller@md-phw.de)
#
# (c) Univ. of Education Weingarten, MEVIS, 2016
#

class Jsonable
  def to_json
    hash = {}
    self.instance_variables.each do |var|
      hash[var] = self.instance_variable_get var
    end
    hash.to_json
  end

  def from_json! string
    JSON.load(string).each do |var, val|
      self.instance_variable_set var, val
    end
  end
end