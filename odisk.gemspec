
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
  s.licenses = ['MIT', 'GPL-3.0']

  s.files = Dir["{lib}/**/*.{rb}"] + ['LICENSE', 'README.md']

  s.executables = Dir["bin/*"].map{ |f| f.split("/")[-1] }

  s.require_paths = ["lib"]

  s.has_rdoc = true
  s.extra_rdoc_files = ['README.md']
  s.rdoc_options = ['--main', 'README.md']

  s.rubyforge_project = 'odisk'

  s.add_runtime_dependency 'oterm', '~> 0'
  s.add_runtime_dependency "opee", '~> 0'
  s.add_runtime_dependency "oj", '~> 0'
  s.add_runtime_dependency "net-ssh", '~> 0'
  s.add_runtime_dependency "net-sftp", '~> 0'

end
