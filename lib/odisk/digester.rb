
require 'etc'

module ODisk
  class Digester < ::Opee::Actor

    def initialize(options={})
      super(options)
    end
    
    def set_options(options)
      super(options)
      @collector = options[:collector]
    end

    private

    def create(job)
      path = ::File.join($local_top, job.path)
      if ::File.directory?(path)
        ::Opee::Env.info("create digest for #{path}")
        d = ::ODisk::Digest.create($local_top, job.path)
      else
        ::Opee::Env.info("#{path} does not exist, no digest")
        d = nil
      end
      job.current_digest = d
      @collector.ask(:collect, job, :digester) unless @collector.nil?
      ::Opee::Env.debug("#{Oj.dump(d, indent: 2)})")
    end
    
  end # Digester
end # ODisk
