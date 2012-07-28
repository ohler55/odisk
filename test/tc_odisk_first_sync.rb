#!/usr/bin/env ruby -wW2
# encoding: UTF-8

$: << File.dirname(__FILE__)
require 'orefs_test_helpers'

require 'oj'

class OrefsTest < ::Test::Unit::TestCase

  def test_orefs_first_sync
    create_top_dir()
    `rm -rf #{$remote_top}`
    #Net::SSH.start(remote.host, remote.user) { |ssh| ssh.exec!("rm -rf #{$remote_top}") }

    out = run_orefs_sync('-u')
    if $debug
      puts out
    else
      assert_equal('', out)
    end
    # get remote digests
    rd1 = nil
    rd2 = nil
    Net::SFTP.start('localhost', ENV['USER']) do |ftp|
      rd1 = Oj.load(read_remote_file(ftp, ::File.join($remote_top, '.orefs/digest.json')), mode: :object)
      rd2 = Oj.load(read_remote_file(ftp, ::File.join($remote_top, 'child/.orefs/digest.json')), mode: :object)

      assert_equal("This is some text.\n", read_remote_file(ftp, ::File.join($remote_top, 'child.txt')))
      assert_equal("This is the grand son.\n", read_remote_file(ftp, ::File.join($remote_top, 'child/grand son')))
      assert_equal("This is the grand daughter.\n", read_remote_file(ftp, ::File.join($remote_top, 'child/grand daughter')))
    end
    d1 = ::Oj.load_file(::File.join($local_top, '.orefs', 'digest.json'), mode: :object)
    d2 = ::Oj.load_file(::File.join($local_top, 'child', '.orefs', 'digest.json'), mode: :object)

    #puts Oj.dump(rd1, indent: 2)
    #puts Oj.dump(rd2, indent: 2)
    # TBD
    assert(::Orefs::Planner.sync_steps(nil, d1, rd1).nil?, 'top digests do not match')
    assert(::Orefs::Planner.sync_steps(nil, d2, rd2).nil?, 'child digests do not match')
  end

end # OrefsTest
