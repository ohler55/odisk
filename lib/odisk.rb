
module ODisk

  # Walk up the directory tree looking for .odisk directories and a
  # remote.json in that directory. If the directory does not exist then stop
  # the walk. If not found check the ~/.odisk/remotes.json file for a matching
  # top.
  def self.gather_remote_info(local_dir, remote)
    top = local_dir
    if remote.user.nil? || remote.host.nil? || remote.dir.nil?
      while ::File.directory?(::File.join(top, '.odisk'))
        rfile = ::File.join(top, '.odisk', 'remote')
        if ::File.file?(rfile)
          rstr = ::File.read(rfile).strip()
          #remote.pass_file = ::File.expand_path(remote.pass_file) unless remote.pass_file.nil? || remote.pass_file.empty?
          orig_pass_file = remote.pass_file
          remote.update(rstr)
          remote.pass_file = ::File.expand_path(remote.pass_file) unless remote.pass_file.nil? || remote.pass_file.empty?
          if !remote.dir.nil? && !remote.dir.empty? && top != $local_top
            remote.dir = remote.dir + local_dir[top.size..-1]
          end
          if remote.pass_file != orig_pass_file && !::File.file?(remote.pass_file)
            remote.pass_file = ::File.join(top, '.odisk', remote.pass_file)
          end
          break
        end
        top = ::File.dirname(top)
      end
    end
    info_from_remotes(local_dir, remote) unless remote.complete?
    remote.user = ENV['USER'] if remote.user.nil?
    unless remote.okay?
      puts "*** user@host:top_dir not specified on command line, in local .odisk/remote file, or in ~/.odisk/remotes"
      return false
    end
    true
  end

  def self.info_from_remotes(local_dir, remote)
    orig_pass_file = remote.pass_file
    local_dir = ::File.expand_path(local_dir)
    remotes_file = ::File.join(::File.expand_path('~'), '.odisk', 'remotes')
    if ::File.file?(remotes_file)
      ::File.readlines(remotes_file).each do |line|
        l,r = line.split(':', 2)
        l = ::File.expand_path(l)
        if l == local_dir || local_dir.start_with?(l + '/')
          remote.update(r)
          remote.dir = remote.dir + remote.dir[l.size..-1] if l != local_dir && !remote.dir.nil?
          if remote.pass_file != orig_pass_file && !::File.file?(remote.pass_file)
            remote.pass_file = ::File.join(::File.expand_path('~'), '.odisk', remote.pass_file)
          end
          break
        end
      end
    end
  end

end

# data
require 'odisk/remote'
require 'odisk/info'
require 'odisk/dir'
require 'odisk/link'
require 'odisk/file'
require 'odisk/digest'
require 'odisk/diff'
# jobs
require 'odisk/dirsyncjob'
require 'odisk/statjob'
require 'odisk/syncjob'
# collectors
require 'odisk/statfixer'
require 'odisk/planner'
# actors
require 'odisk/copier'
require 'odisk/crypter'
require 'odisk/digester'
require 'odisk/fetcher'
require 'odisk/syncstarter'
