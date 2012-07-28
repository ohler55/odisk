
require 'date'
require File.join(File.dirname(__FILE__), 'lib/odisk/version')

Gem::Specification.new do |s|
  s.name = "odisk"
  s.version = ::ODisk::VERSION
  s.authors = "Peter Ohler"
  s.date = Date.today.to_s
  s.email = "peter@ohler.com"
  s.homepage = "http://www.ohler.com/odisk"
  s.summary = "Remote Encrypted File Synchronization, oDisk"
  s.description = %{Remote Encrypted File Synchronization, oDisk}

  s.files = Dir["{lib}/**/*.{rb}"] + ['LICENSE', 'README.md']

  s.executables = Dir["bin/*"].map{ |f| f.split("/")[-1] }

  s.require_paths = ["lib"]

  s.has_rdoc = true
  s.extra_rdoc_files = ['README.md']
  s.rdoc_options = ['--main', 'README.md']
  
  s.rubyforge_project = 'odisk'

  s.add_dependency "opee"
  s.add_dependency "oj"
  s.add_dependency "net-ssh"
  s.add_dependency "net-sftp"

end
