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
require 'odisk'

class ODiskTest < ::Test::Unit::TestCase
end # ODiskTest

require 'tc_odisk_digest'
require 'tc_odisk_first_sync'
require 'tc_odisk_down_sync'
require 'tc_odisk_mods'
require 'tc_odisk_forget'
