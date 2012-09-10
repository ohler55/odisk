#!/usr/bin/env ruby -wW2
# encoding: UTF-8

$: << File.dirname(__FILE__)
require 'odisk_test_helpers'

require 'oj'

class ODiskTest < ::Test::Unit::TestCase

  def test_odisk_remove_file_local
    top = create_top_dir()
    `rm -rf "#{$remote_top}"`

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

    # verify remote digest
    base = ::File.basename(rm)
    path = ::File.join($remote_top, rm + '.gpg')
    digest = Oj.load_file(::File.join(::File.dirname(path), '.odisk', 'digest.json'), mode: :object)
    assert(digest[base].nil?, "remote digest still includes entry for #{base}")
    assert(!::File.exists?(path), "#{path} was not removed, it should not have been")

    # sync with another local
    top2 = ::File.join($local_dir, 'top2')
    out = run_odisk('-s -m remote', top2)
    if $debug
      puts %{--------------------------------------------------------------------------------
Copy top to remote}
      puts out
    else
      assert_equal('', out)
    end
    # verify local digest
    base = ::File.basename(rm)
    path = ::File.join(top2, rm)
    digest = Oj.load_file(::File.join(::File.dirname(path), '.odisk', 'digest.json'), mode: :object)
    assert(digest[base].nil?, "local digest still includes entry for #{base}")
    assert(!::File.exists?(path), "#{path} was not removed, it should not have been")
  end

  def test_odisk_remove_dir_local
    top = create_top_dir()
    `rm -rf "#{$remote_top}"`

    out = run_odisk('-s')
    if $debug
      puts %{--------------------------------------------------------------------------------
Copy top to remote}
      puts out
    else
      assert_equal('', out)
    end

    rm = 'child'
    `rm -rf "#{::File.join(top, rm)}"`

    out = run_odisk('-s -m local')
    if $debug
      puts %{--------------------------------------------------------------------------------
Copy top to remote}
      puts out
    else
      assert_equal('', out)
    end

    # verify remote digest
    base = ::File.basename(rm)
    path = ::File.join($remote_top, rm)
    digest = Oj.load_file(::File.join(::File.dirname(path), '.odisk', 'digest.json'), mode: :object)
    assert(digest[base].nil?, "remote digest still includes entry for #{base}")
    assert(!::Dir.exists?(path), "#{path} was not removed, it should not have been")

    # sync with another local
    top2 = ::File.join($local_dir, 'top2')
    out = run_odisk('-s -m remote', top2)
    if $debug
      puts %{--------------------------------------------------------------------------------
Copy top to remote}
      puts out
    else
      assert_equal('', out)
    end
    # verify local digest
    base = ::File.basename(rm)
    path = ::File.join(top2, rm)
    digest = Oj.load_file(::File.join(::File.dirname(path), '.odisk', 'digest.json'), mode: :object)
    assert(digest[base].nil?, "local digest still includes entry for #{base}")
    assert(!::File.exists?(path), "#{path} was not removed, it should not have been")
  end

  # TBD odisk_remove file
  #  verify local and remote removed
  #  verify sync on top2 also removes

  # TBD explicit remove dir
  # TBD implicit sync 

end # ODiskTest
