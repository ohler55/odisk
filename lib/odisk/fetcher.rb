
begin
  v = $VERBOSE
  $VERBOSE = false
  require 'net/ssh'
  require 'net/sftp'
  $VERBOSE = v
end
require 'oj'

module ODisk
  class Fetcher < ::Opee::Actor

    def initialize(options={})
      @ftp = nil
      super(options)
    end
    
    def set_options(options)
      super(options)
      @collector = options[:collector]
    end

    def close()
      @ftp.close_channel() unless @ftp.nil?
      @ftp = nil
      super()
    end

    private

    def fetch(job)
      top = (job.path.nil? || job.path.empty?) ? $remote.dir : ::File.join($remote.dir, job.path)
      path = ::File.join(top, '.orefs', 'digest.json')
      ::Opee::Env.info("fetch digest \"#{path}\"")
      @ftp = Net::SFTP.start($remote.host, $remote.user) if @ftp.nil?
      begin
        json = @ftp.download!(path)
        files = @ftp.dir.entries(top).map {|e| e.name }
        job.remote_digest = Oj.load(json, mode: :object)
        missing = []
        job.remote_digest.entries.each { |e| missing << e.name unless files.include?(e.name + '.gpg') || files.include?(e.name) }
        unless ::ODisk::Planner::Step::REMOTE == $master
          missing.each { |name| job.remote_digest.delete(name) }
        end
      rescue Exception
        job.remote_digest = nil
      end
      @collector.ask(:collect, job, :fetcher) unless @collector.nil?
      ::Opee::Env.debug("#{Oj.dump(job.remote_digest, indent: 2)})")
    end
    
  end # Fetcher
end # ODisk
