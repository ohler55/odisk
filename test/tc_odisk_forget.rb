#!/usr/bin/env ruby -wW2
# encoding: UTF-8

$: << File.dirname(__FILE__)
require 'odisk_test_helpers'

require 'oj'

class ODiskTest < ::Test::Unit::TestCase

  def test_odisk_forget_file
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

    forget = 'child/grand son'
    out = run_odisk_forget('-s', top, forget)
    if $debug
      puts %{--------------------------------------------------------------------------------
Forget "#{forget}"}
      puts out
    else
      assert_equal('', out)
    end

    path = ::File.join(top, forget)
    base = ::File.basename(path)
    digest = Oj.load_file(::File.join(::File.dirname(path), '.odisk', 'digest.json'), mode: :object)
    assert(digest[base].nil?, "local digest still includes entry for #{base}")

    assert(::File.exists?(path), "#{path} was removed, it should not have been")

    # verify remote digest
    path = ::File.join($remote_top, forget + '.gpg')
    digest = Oj.load_file(::File.join(::File.dirname(path), '.odisk', 'digest.json'), mode: :object)
    assert(digest[base].nil?, "local digest still includes entry for #{base}")

    assert(!::File.exists?(path), "#{path} was not removed, it should not have been")
  end

  def test_odisk_forget_dir
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

    forget = 'child'
    out = run_odisk_forget('-s', top, forget)
    if $debug
      puts %{--------------------------------------------------------------------------------
Forget "#{forget}"}
      puts out
    else
      assert_equal('', out)
    end

    path = ::File.join(top, forget)
    base = ::File.basename(path)
    digest = Oj.load_file(::File.join(::File.dirname(path), '.odisk', 'digest.json'), mode: :object)
    assert(digest[base].nil?, "local digest still includes entry for #{base}")

    assert(::File.exists?(path), "#{path} was removed, it should not have been")

    # verify remote digest
    path = ::File.join($remote_top, forget + '.gpg')
    digest = Oj.load_file(::File.join(::File.dirname(path), '.odisk', 'digest.json'), mode: :object)
    assert(digest[base].nil?, "local digest still includes entry for #{base}")

    assert(!::File.exists?(path), "#{path} was not removed, it should not have been")
  end

end # ODiskTest
