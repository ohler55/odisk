
require 'oj'

module ODisk
  # The Planner collects input in the form of Digests from a Digester and a
  # Fetcher and then determines what actions are necessary to synchronize a
  # directory. The Planner then asks Copiers and Crypters to perform the
  # synchronization operations.
  class Planner < ::Opee::Collector

    def initialize(options={})
      super(options)
    end

    def set_options(options)
      super(options)
      @dir_queue = options[:dir_queue]
      @copy_queue = options[:copy_queue]
      @crypt_queue = options[:crypt_queue]
      @inputs = options[:inputs]
      @fixer = options[:fixer]
    end

    # master can be Step::LOCAL or Step::REMOTE and forces direction
    def self.sync_steps(pd, ld, rd, master=nil)
      steps = {}
      lh = {}
      rh = {}
      ph = {}
      ld.entries.each { |e| lh[e.name] = e }
      rd.entries.each { |e| rh[e.name] = e }
      pd.entries.each { |e| ph[e.name] = e } unless pd.nil?
      keys = lh.keys | rh.keys
      keys.each do |name|
        le = lh[name]
        re = rh[name]
        if re.nil?
          if Step::REMOTE == master
            steps[name] = Step.new(name, Step::LOCAL, Step::REMOVE)
          elsif le.is_a?(::ODisk::File)
            steps[name] = Step.new(name, Step::LOCAL, Step::COPY)
          elsif le.is_a?(::ODisk::Dir)
            steps[name] = Step.new(name, Step::LOCAL, Step::DIGEST)
          end
        elsif le.nil?
          if Step::LOCAL == master
            steps[name] = Step.new(name, Step::REMOTE, Step::REMOVE)
          elsif re.is_a?(::ODisk::File)
            steps[name] = Step.new(name, Step::REMOTE, Step::COPY)
          elsif re.is_a?(::ODisk::Dir)
            steps[name] = Step.new(name, Step::REMOTE, Step::DIGEST)
          end
        elsif le != re # both exist but are different
          # some helpful info
          if le.owner != re.owner
            ::Opee::Env.info("#{le.name} owner difference #{le.owner} != #{re.owner}")
          elsif le.group != re.group
            ::Opee::Env.info("#{le.name} group difference #{le.group} != #{re.group}")
          elsif le.mode != re.mode
            ::Opee::Env.info("#{le.name} mode difference #{le.mode} != #{re.mode}")
          elsif le.mtime.sec != re.mtime.sec
            ::Opee::Env.info("#{le.name} mtime (sec) difference #{le.mtime.sec} != #{re.mtime.sec}")
          elsif le.size != re.size
            ::Opee::Env.info("#{le.name} size difference #{le.size} != #{re.size}")
          end

          if le.class != re.class
            ::Opee::Env.error("Conflict syncing #{ld.top_path}/#{name}. Local and remote types do not match.")
            steps[name] = Step.new(name, Step::LOCAL, Step::ERROR)
          elsif le.removed
            ::Opee::Env.error("Unexpected digest entry for #{ld.top_path}/#{name}. The removed flag is sent in the local digest.")
          elsif re.removed
            steps[name] = Step.new(name, Step::LOCAL, Step::REMOVE)
          elsif le.is_a?(::ODisk::File) || le.is_a?(::ODisk::Link)
            op = le.is_a?(::ODisk::File) ? Step::COPY : Step::LINK
            if Step::LOCAL == master
              steps[name] = Step.new(name, Step::LOCAL, op) if le.is_a?(::ODisk::File)
            elsif Step::REMOTE == master
              steps[name] = Step.new(name, Step::REMOTE, op) if re.is_a?(::ODisk::File)
            elsif le.mtime > re.mtime
              pe = ph[name]
              if pe.nil? || pe.mtime == re.mtime
                # Don't know if the content or the stats changed so copy it.
                steps[name] = Step.new(name, Step::LOCAL, op) if le.is_a?(::ODisk::File)
              else
                ::Opee::Env.error("Conflict syncing #{ld.top_path}/#{name}. Both local and remote have changed.")
                steps[name] = Step.new(name, Step::LOCAL, Step::ERROR)
              end
            elsif le.mtime < re.mtime
              # Don't know if the content or the stats changed so copy it.
              steps[name] = Step.new(name, Step::REMOTE, op) if re.is_a?(::ODisk::File)
            else # same times but different can't be good
              ::Opee::Env.error("Conflict syncing #{ld.top_path}/#{name}. Both local and remote have changed.")
              steps[name] = Step.new(name, Step::LOCAL, Step::ERROR)
            end
          end
        end
      end
      steps.empty? ? nil : steps
    end

    private

    def update_token(job, token, path_id)
      token = [] if token.nil?
      token << path_id
      token
    end

    def complete?(job, token)
      result = !token.nil? && token.size == @inputs.size && token.sort == @inputs.sort
      ::Opee::Env.info("complete?(#{job.key()}, #{token}) => #{result}")
      #::Opee::Env.debug("#{Oj.dump(job, indent: 2)}")
      result
    end

    def keep_going(job)
      path = ::File.join($local_top, job.path)
      odisk_dir = ::File.join(path, '.odisk')
      `mkdir -p "#{odisk_dir}"` unless ::File.directory?(odisk_dir) && !$dry_run
      if @copy_queue.nil? && @crypt_queue.nil? && !job.current_digest.nil? # digests_only
        if job.previous_digest.nil?
          job.current_digest.version = 1
        else
          job.current_digest.version = job.previous_digest.version + 1
          Oj.to_file(::File.join(odisk_dir, 'digest.old.json'), job.previous_digest, indent: 2)
        end
        Oj.to_file(::File.join(odisk_dir, 'digest.json'), job.current_digest, indent: 2)
        job.current_digest.entries.each do |e|
          @dir_queue.ask(:add, job.path.empty? ? e.name : ::File.join(job.path, e.name)) if e.is_a?(::ODisk::Dir)
        end
      elsif job.remote_digest.nil?
        process_new(job, odisk_dir)
      elsif ((job.current_digest.nil? || job.current_digest.empty?) &&
             (job.previous_digest.nil? || job.previous_digest.empty?))
        process_down(job, odisk_dir)
      else
        process_sync(job, odisk_dir)
      end
    end

    def process_new(job, odisk_dir)
      job.current_digest.version = 1
      job.new_digest = job.current_digest
      # determine update new_digest
      # write the digest files
      # TBD if they are the same then don't bother
      Oj.to_file(::File.join(odisk_dir, 'digest.old.json'), job.previous_digest, indent: 2) unless job.previous_digest.nil?
      Oj.to_file(::File.join(odisk_dir, 'digest.json'), job.new_digest, indent: 2)
      # get the transfers going for all files
      job.new_digest.entries.each do |e|
        path = job.path.empty? ? e.name : ::File.join(job.path, e.name)
        case e
        when ::ODisk::Dir
          @dir_queue.ask(:add, path)
        when ::ODisk::File
          local = ::File.join($local_top, path)
          remote = ::File.join($remote.dir, path)
          if $remote.encrypt?
            encrypt_path = (job.path.empty? ?
                            ::File.join($local_top, '.odisk', e.name + '.gpg') :
                            ::File.join($local_top, job.path, '.odisk', e.name + '.gpg'))
            @crypt_queue.add_method(:encrypt, local, encrypt_path, remote + '.gpg')
          else
            @copy_queue.add_method(:upload, local, remote)
          end
        when ::ODisk::Link
          # nothing to do
        end
      end
      path = job.path.empty? ? ::File.join('.odisk', 'digest.json') : ::File.join(job.path, '.odisk', 'digest.json')
      local = ::File.join($local_top, path)
      remote = ::File.join($remote.dir, path)
      @copy_queue.add_method(:upload, local, remote)
    end

    def process_down(job, odisk_dir)
      job.new_digest = job.remote_digest
      Oj.to_file(::File.join(odisk_dir, 'digest.json'), job.new_digest, indent: 2)
      full_job_path = job.path.empty? ? $local_top : ::File.join($local_top, job.path)
      stat_job = StatJob.new(full_job_path, job.new_digest)
      job.new_digest.entries.each do |e|
        path = job.path.empty? ? e.name : ::File.join(job.path, e.name)
        local = ::File.join($local_top, path)
        case e
        when ::ODisk::Dir
          ::Dir.mkdir(local) unless $dry_run || ::File.directory?(local)
          @dir_queue.ask(:add, path)
        when ::ODisk::File
          remote = ::File.join($remote.dir, path)
          stat_job.add_mod(e.name)
          if $remote.encrypt?
            encrypt_path = (job.path.empty? ?
                            ::File.join($local_top, '.odisk', e.name + '.gpg') :
                            ::File.join($local_top, job.path, '.odisk', e.name + '.gpg'))
            @copy_queue.add_method(:download, remote + '.gpg', encrypt_path, local)
          else
            @copy_queue.add_method(:download, remote, local, nil)
          end
        when ::ODisk::Link
          target = e.target
          target = ::File.join($local_top, e.target) unless '/' == target[0]
          ::Opee::Env.info("symlink \"#{local}\" -> \"#{target}\"}")
          ::File.symlink(target, local) unless $dry_run || ::File.exists?(local)
        end
      end
      @fixer.ask(:collect, stat_job, :planner) unless @fixer.nil?
    end

    def process_sync(job, odisk_dir)
      dirs = []
      if Step::REMOTE == $master
        job.remote_digest.entries.each { |e| dirs << e.name unless !e.is_a?(::ODisk::Dir) || dirs.include?(e.name) }
      elsif Step::LOCAL == $master
        job.current_digest.entries.each { |e| dirs << e.name unless !e.is_a?(::ODisk::Dir) || dirs.include?(e.name) }
      else
        job.current_digest.entries.each { |e| dirs << e.name unless !e.is_a?(::ODisk::Dir) || dirs.include?(e.name) }
        job.remote_digest.entries.each do |e|
          next unless e.is_a?(::ODisk::Dir)
          if e.removed
            dirs.delete(e.name)
          else
            dirs << e.name unless dirs.include?(e.name)
          end
        end
      end
      dirs.each do |dir|
        path = job.path.empty? ? dir : ::File.join(job.path, dir)
        local = ::File.join($local_top, path)
        ::Dir.mkdir(local) unless $dry_run || ::File.directory?(local)
        @dir_queue.ask(:add, path)
      end
      steps = self.class.sync_steps(job.previous_digest, job.current_digest, job.remote_digest, $master)
      #puts "*** steps for #{job.path}: #{steps}"
      return if steps.nil?

      Oj.to_file(::File.join(odisk_dir, 'digest.old.json'), job.previous_digest, indent: 2) unless job.previous_digest.nil?
      nrh = {} # fill with new digest entries for remote
      nlh = {} # fill with new digest entries for local
      full_job_path = job.path.empty? ? $local_top : ::File.join($local_top, job.path)
      stat_job = StatJob.new(full_job_path, nil)
      job.remote_digest.entries.each { |e| nrh[e.name] = e }
      job.current_digest.entries.each { |e| nlh[e.name] = e }
=begin
      if job.previous_digest.nil?
        job.current_digest.entries.each { |e| nlh[e.name] = e }
      else
        job.previous_digest.entries.each { |e| nlh[e.name] = e }
      end
=end
      steps.values.each do |s|
        stat_job.add_mod(s.name) unless Step::REMOVE == s.op || Step::DIGEST == s.op
        case s.op
        when Step::COPY
          path = job.path.empty? ? s.name : ::File.join(job.path, s.name)
          local = ::File.join($local_top, path)
          remote = ::File.join($remote.dir, path)
          encrypt_path = (job.path.empty? ?
                          ::File.join($local_top, '.odisk', s.name + '.gpg') :
                          ::File.join($local_top, job.path, '.odisk', s.name + '.gpg'))
          if Step::REMOTE == s.master
            if $remote.encrypt?
              @copy_queue.add_method(:download, remote + '.gpg', encrypt_path, local)
            else
              @copy_queue.add_method(:download, remote, local, nil)
            end
            e = job.remote_digest[s.name]
          else
            if $remote.encrypt?
              @crypt_queue.add_method(:encrypt, local, encrypt_path, remote + '.gpg')
            else
              @copy_queue.add_method(:upload, local, remote)
            end
            e = job.current_digest[s.name]
          end
          nrh[e.name] = e
          nlh[e.name] = e
        when Step::REMOVE
          path = job.path.empty? ? s.name : ::File.join(job.path, s.name)
          if Step::REMOTE == s.master
            remote = ::File.join($remote.dir, path)
            @copy_queue.add_method(:remove_remote, remote)
            nrh.delete(s.name)
          else
            local = ::File.join($local_top, path)
            @copy_queue.add_method(:remove_local, local)
            nlh.delete(s.name)
          end
        when Step::DIGEST
          e = (Step::REMOTE == s.master) ? job.remote_digest[s.name] : job.current_digest[s.name]
          nrh[e.name] = e
          nlh[e.name] = e
        when Step::LINK
          # Handled in StatFixer
        when Step::ERROR
          # TBD
        end
      end
      nrd = Digest.new(job.remote_digest.top_path)
      nld = Digest.new(job.current_digest.top_path)
      # fill in digest entries from hashs
      nrd.entries = nrh.values
      nld.entries = nlh.values

      job.new_digest = nrd
      remote_digest_path = ::File.join(odisk_dir, 'digest.remote.json')
      Oj.to_file(::File.join(odisk_dir, 'digest.json'), nld, indent: 2)
      Oj.to_file(remote_digest_path, job.new_digest, indent: 2)
      path = job.path.empty? ? ::File.join('.odisk', 'digest.json') : ::File.join(job.path, '.odisk', 'digest.json')
      @copy_queue.add_method(:upload, remote_digest_path, ::File.join($remote.dir, path)) unless Step::REMOTE == $master

      stat_job.digest = nld
      @fixer.ask(:collect, stat_job, :planner) unless @fixer.nil?
    end

    class Step
      # op values
      STATS  = 0
      REMOVE = 1
      COPY   = 2
      LINK   = 3
      DIGEST = 4
      ERROR  = 5

      # location of master
      LOCAL  = true
      REMOTE = false

      attr_reader :name
      attr_reader :master
      attr_reader :op

      def initialize(name, master, op)
        @name = name
        @master = master
        @op = op
      end

      def to_s()
        "<Step name=#{@name} master=#{@master ? 'LOCAL' : 'REMOTE'} op=#{['STATS', 'REMOVE', 'COPY', 'LINK', 'ERROR'][@op]}>"
      end
    end # Step

  end # Planner
end # ODisk
