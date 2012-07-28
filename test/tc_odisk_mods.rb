#!/usr/bin/env ruby -wW2
# encoding: UTF-8

$: << File.dirname(__FILE__)
require 'odisk_test_helpers'

require 'oj'

class ODiskTest < ::Test::Unit::TestCase

  def test_odisk_mods
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
    # now create a new local and verify the new and old are the same
    top2 = ::File.join($local_dir, 'top2')
    `rm -rf "#{top2}"`
    out = run_odisk('-s', top2)
    if $debug
      puts %{--------------------------------------------------------------------------------
Copy remote to top2}
      puts out
    else
      assert_equal('', out)
    end
    diffs = ::ODisk::Diff.dir_diff($local_top, top2, true)
    assert_equal({}, diffs)

    # Modify child.txt content. It should be copied over to master and then top2.
    ::File.open(::File.join(top, 'child.txt'), 'w') { |f| f.write("This is some other text.\n") }
    # Modify the date of 'grand son' so that mismatch detection can be
    # checked. In top2 the content will be changed but not the time.
    now = Time.now()
    ::File.utime(now, now, ::File.join(top, 'child', 'grand son'))

    out = run_odisk('-s', top)
    if $debug
      puts %{--------------------------------------------------------------------------------
Modify child.txt and set date on 'child/grand son' then sync with remote}
      puts out
    else
      assert_equal('', out)
    end

    out = run_odisk('-s', top2)
    if $debug
      puts %{--------------------------------------------------------------------------------
Sync top2}
      puts out
    else
      assert_equal('', out)
    end
    # top and top2 should be in sync with the new child.txt content
    assert_equal("This is some other text.\n", ::File.read(::File.join(top2, 'child.txt')))
    diffs = ::ODisk::Diff.dir_diff(top, top2, true)
    assert_equal({}, diffs)

    ::File.open(::File.join(top2, 'child', 'grand son'), 'w') { |f| f.write("This is the grandson.\n") }
    ::File.utime(now, now, ::File.join(top2, 'child', 'grand son'))

    out = run_odisk('-s', top2)
    out_lines = out.split("\n")
    if $debug
      puts %{--------------------------------------------------------------------------------
Expecting 'child/grand son' to have a syncing conflict}
      (0...out_lines.size).each { |i| puts "%02d: %s" % [i + 1, out_lines[i]] }
    else
      #(0...out_lines.size).each { |i| puts "%02d: %s" % [i + 1, out_lines[i]] }
      assert_equal(1, out_lines.size)
      assert_equal(true, out_lines[0].include?('Conflict syncing child/grand son'))
    end
    # top/child and top2/child digests should still match so that a rerun will
    # yield the same error.
    assert_equal(::File.read(::File.join(top, 'child', '.odisk', 'digest.json')),
                 ::File.read(::File.join(top, 'child', '.odisk', 'digest.json')))

    out = run_odisk('-m local -s', top2)
    if $debug
      puts %{--------------------------------------------------------------------------------
Force top2 changes to remote}
      puts out
    else
      assert_equal('', out)
    end
    out = run_odisk('-m remote -s', top)
    if $debug
      puts %{--------------------------------------------------------------------------------
Force remote to top}
      puts out
    else
      assert_equal('', out)
    end

    diffs = ::ODisk::Diff.dir_diff(top, top2, true)
    assert_equal({}, diffs)
  end

  # create top, remote, and top2
  # change mode, user, and group, might need to touch if dates do not change or sleep 1 before changing
  #   compare
  # TBD change mode and group
=begin
  - test
   - create local/top
   - sync to remote
   - sync to local/top2
   - in top
    - modify file (child.txt)
    - change group
    - change mode
     - must compare previous mode and owner/group with current
     - if changed then propogate to master, else use remote
    - change content of grand son in both
     - verify conflict is detected
=end

end # ODiskTest
