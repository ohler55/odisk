
module ODisk

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
