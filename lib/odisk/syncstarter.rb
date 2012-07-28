
module ODisk
  class SyncStarter < ::Opee::Actor

    def initialize(options={})
      @digester = nil
      @fetcher = nil
      super(options)
      @dir_queue.ask(:ready, self)
    end
    
    def set_options(options)
      super(options)
      @dir_queue = options[:dir_queue]
      @digester = options[:digester]
      @fetcher = options[:fetcher]
      @collector = options[:collector]
    end

    private

    def start(path)
      ::Opee::Env.info("start sync for #{path}")
      job = DirSyncJob.new(path)
      @fetcher.ask(:fetch, job) unless @fetcher.nil?
      @digester.ask(:create, job) unless @digester.nil?

      top = (path.nil? || path.empty?) ? $local_top : ::File.join($local_top, path)
      prev_path = ::File.join(top, '.odisk', 'digest.json')
      job.previous_digest = ::Oj.load_file(prev_path, mode: :object) if ::File.file?(prev_path)
      @collector.ask(:collect, job, :starter) unless @collector.nil?
      # ready for another
      @dir_queue.ask(:ready, self)
    end
    
  end # SyncStarter
end # ODisk
