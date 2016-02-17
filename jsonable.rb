#
# Project: portfolio_anaylzer
# File: JSONeable
#
# Description:
# Provides a base class to simplify JSON serialization. This approach follows in principle
# http://stackoverflow.com/questions/4464050/ruby-objects-and-json-serialization-without-rails
# However, several adaptions were necessary to get this really working ...
#
# Author(s):
# Wolfgang Mueller, Univ. of Education Weingarten, MEVIS (mueller@md-phw.de)
#
# (c) Univ. of Education Weingarten, MEVIS, 2016
#

require 'json'

class Jsonable
  def self.json_creatable?
    true
  end

  def to_json(*a)
    res = {'json_class' => self.class.name}
    hash = {}
    self.instance_variables.each do |var|
      hash[var] = self.instance_variable_get var
    end
    res['data'] = hash
    res.to_json(*a)
  end

  def self.json_create_orig(o)
    #new(*o['data'])
  end

  def self.json_create(object)
    obj = new
    for key, value in object['data']
      next if key == JSON.create_id
      obj.instance_variable_set key.to_sym, value
    end
    obj
  end

  # deprecated: does not comply to the new approach in to_json
  def from_json! string
    obj = JSON.parse(string)
    for key, value in obj['data']
      next if key == JSON.create_id
      self.instance_variable_set key.to_sym, value
    end
    #JSON.load(string).each do |var, val|
    #  self.instance_variable_set var, val
    #end
  end

end