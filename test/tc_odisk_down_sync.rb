#!/usr/bin/env ruby -wW2
# encoding: UTF-8

$: << File.dirname(__FILE__)
require 'orefs_test_helpers'

require 'oj'

class OrefsTest < ::Test::Unit::TestCase

  def test_orefs_download
    create_top_dir()
    `rm -rf #{$remote_top}`
    #Net::SSH.start(remote.host, remote.user) { |ssh| ssh.exec!("rm -rf #{$remote_top}") }

    out = run_orefs_sync('')
    if $debug
      puts out
    else
      assert_equal('', out)
    end
    # now create a new local and verify the new and old are the same
    top2 = ::File.join($local_dir, 'top2')
    `rm -rf "#{top2}"`

    out = run_orefs_sync('', top2)
    if $debug
      puts out
    else
      assert_equal('', out)
    end
    diffs = ::Orefs::Diff.dir_diff($local_top, top2, true)
    #puts "*** diffs: #{diffs.values.join('')}"
    assert_equal({}, diffs)
  end

end # OrefsTest
