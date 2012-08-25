#!/usr/bin/env ruby -wW2
# encoding: UTF-8

$: << File.dirname(__FILE__)
require 'odisk_test_helpers'

require 'oj'

class ODiskTest < ::Test::Unit::TestCase

  def test_odisk_remove_file_local
    top = create_top_dir()
    `rm -rf #{$remote_top}`

    out = run_odisk('-s')
    if $debug
      puts %{--------------------------------------------------------------------------------
Copy top to remote}
      puts out
    else
      assert_equal('', out)
    end

    rm = 'child/grand son'
    ::File.delete(::File.join(top, rm))

    out = run_odisk('-s -m local')
    if $debug
      puts %{--------------------------------------------------------------------------------
Copy top to remote}
      puts out
    else
      assert_equal('', out)
    end

    # TBD verify remote has been removed and digest updated

    # verify remote digest
    base = ::File.basename(rm)
    path = ::File.join($remote_top, rm + '.gpg')
    digest = Oj.load_file(::File.join(::File.dirname(path), '.odisk', 'digest.json'), mode: :object)
    assert(digest[base].nil?, "remote digest still includes entry for #{base}")
    assert(!::File.exists?(path), "#{path} was not removed, it should not have been")

  end

  # TBD remove dir
  # TBD explicit remove file
  # TBD explicit remove dir

end # ODiskTest
