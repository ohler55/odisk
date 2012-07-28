#!/usr/bin/env ruby -wW2
# encoding: UTF-8

$: << File.dirname(__FILE__)
require 'odisk_test_helpers'

class ODiskTest < ::Test::Unit::TestCase

  def test_odisk_diff
    here = ::File.expand_path(::File.dirname(__FILE__))
    top = create_top_dir()
    top2 = top + '2'
    `rm -r "#{top2}"`
    tar = top + '.tar'
    `tar -cpf "#{tar}" local/top`
    `mv "#{top}" "#{top2}"`
    `tar -xf "#{tar}"`
    ::File.chmod(mode_to_i('rwx------'), ::File.join(top2, 'child.txt'))
    `chown -R ohler:staff "#{top2}"`

    # TBD change times

    # TBD fix relative link after check

    # TBD change stuff
    diffs = ::ODisk::Diff.dir_diff(top, top2, true)
    puts "*** diffs: #{diffs}"
  end

end # ODiskTest
