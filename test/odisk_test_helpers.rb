#!/usr/bin/env ruby -wW2
# encoding: UTF-8

$debug = !ARGV.delete('-d').nil?

[ File.dirname(__FILE__),
  File.join(File.dirname(__FILE__), "../lib"),
  File.join(File.dirname(__FILE__), "../../oj/lib"), # TBD temporary
  File.join(File.dirname(__FILE__), "../../oj/ext"), # TBD temporary
  File.join(File.dirname(__FILE__), "../../opee/lib"), # TBD temporary
].each { |path| $: << path unless $:.include?(path) }

require 'test/unit'
require 'opee'
require 'odisk'
begin
  v = $VERBOSE
  $VERBOSE = false
  require 'net/ssh'
  require 'net/sftp'
  $VERBOSE = v
end

$here = ::File.expand_path(::File.dirname(__FILE__))
$local_dir = ::File.join($here, 'local')
$remote_dir = ::File.join($here, 'remote')
::Dir.mkdir($local_dir) unless ::Dir.exists?($local_dir)
::Dir.mkdir($remote_dir) unless ::Dir.exists?($remote_dir)
$local_top = ::File.join($local_dir, 'top')
$remote_top = ::File.join($remote_dir, 'top')


def run_odisk(options='', top=nil)
  top = $local_top if top.nil?
  #puts %{#{::File.dirname($here)}/bin/odisk -r #{ENV['USER']}@localhost:#{$remote_top}:#{::File.join($here, 'test.pass')} #{options} #{$debug ? '-v' : ''} "#{top}"}
  `#{::File.dirname($here)}/bin/odisk -r #{ENV['USER']}@localhost:#{$remote_top}:#{::File.join($here, 'test.pass')} #{options} #{$debug ? '-v' : ''} "#{top}"`
end

def run_odisk_forget(options='', top=nil, forget=nil)
  top = $local_top if top.nil?
  `#{::File.dirname($here)}/bin/odisk_forget -r #{ENV['USER']}@localhost:#{$remote_top}:#{::File.join($here, 'test.pass')} #{options} #{$debug ? '-v' : ''} "#{top}" "#{forget}"`
end

def run_odisk_remove(options='', top=nil, rm=nil)
  top = $local_top if top.nil?
  `#{::File.dirname($here)}/bin/odisk_remove -r #{ENV['USER']}@localhost:#{$remote_top}:#{::File.join($here, 'test.pass')} #{options} #{$debug ? '-v' : ''} "#{top}" "#{rm}"`
end

def mode_to_i(ms)
  m = 0
  raise "#{ms} is not a valid mode string" unless 9 == ms.size 
  9.times do |i|
    c = ms[i]
    if 'rwxrwxrwx'[i] == c
      m += 0400 >> i
    elsif '-' != c
      raise "#{ms} is not a valid mode string"
    end
  end
  m
end

def create_top_dir()
  `rm -rf #{$local_top}`
  ::Dir.mkdir($local_top)
  ::File.open(::File.join($local_top, 'child.txt'), 'w') { |f| f.write("This is some text.\n") }
  ::File.symlink(::File.join($local_top, 'child.txt'), ::File.join($local_top, 'child.link'))
  ::Dir.mkdir(::File.join($local_top, 'child'))
  ::File.open(::File.join($local_top, 'child', 'grand son'), 'w') { |f| f.write("This is the grand son.\n") }
  gd = ::File.join($local_top, 'child', 'grand daughter')
  ::File.open(gd, 'w') { |f| f.write("This is the grand daughter.\n") }
  ::File.chown(nil, Etc.getgrnam('admin').gid, gd)
  $local_top
end

def read_remote_file(ftp, filename)
  h = ftp.open!(filename)
  str = ftp.read!(h, 0, 4096)
  ftp.close(h)
  str
end

def file_diff(p1, p2)
  return "#{::File.basename(p1)} only exists in #{p2}\n" unless ::File.exist?(p1)
  return "#{::File.basename(p1)} only exists in #{p1}\n" unless ::File.exist?(p2)
  s1 = File.lstat(p1)
  s2 = File.lstat(p2)
  return "#{p1} and #{p2} differ in type\n" unless s1.ftype == s2.ftype
  msg = ''
  case s1.ftype
  when 'directory'
    msg << dir_diff(p1, p2)
  when 'file'
    # size and content
  when 'link'
    # target
  else
    return "#{p1}/#{p2} are an unknown type\n"
  end
  # TBD check owner and group
  # TBD check mode
  # TBD check times
  msg
end

def dir_diff(d1, d2)
  s = ''
  e1 = ::Dir.entries(d1)
  e2 = ::Dir.entries(d2)
  keys = e1 | e2
  keys.delete('.')
  keys.delete('..')
  keys.each do |name|
    s << file_diff(::File.join(d1, name), ::File.join(d2, name))
  end
  s
end
