#!/usr/bin/env ruby -wW2
# encoding: UTF-8

if __FILE__ == $0
  $debug = !ARGV.delete('-d').nil?
end

[ File.dirname(__FILE__),
  File.join(File.dirname(__FILE__), "../lib"),
  File.join(File.dirname(__FILE__), "../../oj/lib"), # TBD temporary
  File.join(File.dirname(__FILE__), "../../oj/ext"), # TBD temporary
  File.join(File.dirname(__FILE__), "../../opee/lib"), # TBD temporary
].each { |path| $: << path unless $:.include?(path) }

require 'test/unit'
require 'oj'
require 'opee'
require 'orefs'

class OrefsTest < ::Test::Unit::TestCase
end # OrefsTest

require 'tc_orefs_digest'
require 'tc_orefs_first_sync'
require 'tc_orefs_down_sync'
require 'tc_orefs_mods'
