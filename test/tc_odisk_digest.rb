#!/usr/bin/env ruby -wW2
# encoding: UTF-8

$: << File.dirname(__FILE__)
require 'odisk_test_helpers'

class ODiskTest < ::Test::Unit::TestCase

  def test_odisk_digest_tree
    top = create_top_dir()
    out = run_odisk('-d')
    if $debug
      puts out
    else
      assert_equal('', out)
    end

    digest = ::Oj.load_file(::File.join(top, '.odisk', 'digest.json'), mode: :object)
    #puts ::Oj.dump(digest, indent: 2)
    assert_equal('', digest.top_path)
    assert_equal(1, digest.version)
    assert_equal(3, digest.entries.size)
    digest.entries.each do |e|
      assert_equal(Time, e.mtime.class)
      case e.name
      when 'child'
        assert_equal(::ODisk::Dir, e.class)
      when 'child.txt'
        assert_equal(::ODisk::File, e.class)
        assert_equal(19, e.size)
      when 'child.link'
        assert_equal(::ODisk::Link, e.class)
        assert_equal('child.txt', e.target)
      else
        assert(false, "#{e.name} was not an expected entry")
      end
    end
    # now the child dir
    d2 = ::Oj.load_file(::File.join(top, 'child', '.odisk', 'digest.json'), mode: :object)
    #puts ::Oj.dump(d2, indent: 2)
    assert_equal('child', d2.top_path)
    assert_equal(1, d2.version)
    assert_equal(2, d2.entries.size)
    d2.entries.each do |e|
      case e.name
      when 'grand son'
        assert_equal(::ODisk::File, e.class)
        assert_equal(23, e.size)
      when 'grand daughter'
        assert_equal(::ODisk::File, e.class)
        assert_equal(28, e.size)
        assert_equal('admin', e.group)
      else
        assert(false, "#{e.name} was not an expected entry")
      end
    end
  end

  def test_odisk_digest_mode
    `rm -rf #{$local_top}`
    ::Dir.mkdir($local_top)
    [ 'rwxr--r--',
      'rwxrw-rw-',
      'rwxrwxrwx',
      'rwx------'
    ].each do |m|
      mi = mode_to_i(m)
      filename = ::File.join($local_top, "file_#{m}")
      ::File.open(filename, 'w') { |f| f.write("mode should be #{m}.\n") }
      ::File.chmod(mi, filename)

      linkname = ::File.join($local_top, "link_#{m}")
      ::File.symlink(filename, linkname)
      ::File.lchmod(mi, linkname)

      dirname = ::File.join($local_top, "dir_#{m}")
      ::Dir.mkdir(dirname)
      ::File.chmod(mi, dirname)
    end
    
    out = run_odisk('-d')
    if $debug
      puts out
    else
      assert_equal('', out)
    end
    digest = ::Oj.load_file(::File.join($local_top, '.odisk', 'digest.json'), mode: :object)
    digest.entries.each do |e|
      assert_equal(mode_to_i(e.name[-9..-1]), e.mode, "#{e.name} failed, expected %04o but was %04o" % [mode_to_i(e.name[-9..-1]), e.mode])
    end
  end

end # ODiskTest
