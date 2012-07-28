
module ODisk
  class StatFixer < ::Opee::Collector

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

    private

    def job_key(job)
      if job.is_a?(StatJob)
        job.key()
      elsif job.is_a?(String)
        ::File.dirname(job)
      else
        raise "Invalid path for StatFixer"
      end      
    end

    def update_token(job, token, path_id)
      # StatJob or String (a file path) can be received
      if job.is_a?(StatJob)
        if token.nil?
          job.digest.entries.each do |e|
            fix_stats(::File.join(job.path, e.name), e) unless job.mods.include?(e.name)
          end
        elsif token.is_a?(Array)
          until (path = token.pop).nil?
            name = ::File.basename(path)
            fix_stats(path, job.digest.entries[name])
            job.mods.delete(name)
          end
        else
          raise "Expected StatFixer token to be an Array or nil"
        end
        token = job
      else
        if token.nil?
          token = [job]
        elsif token.is_a?(Array)
          token << job
        elsif token.is_a?(StatJob)
          name = ::File.basename(job)
          fix_stats(job, token.digest[name])
          token.mods.delete(name)
        else
          raise "Expected StatFixer token to be an Array, StatJob, or nil"
        end
      end
      token
    end

    def complete?(job, token)
      result = token.is_a?(StatJob) ? token.complete?(token) : false
      ::Opee::Env.info("complete?(#{job}, #{token}) => #{result}")
      result
    end

    def keep_going(job)
      # done, nothing left to do
      # TBD tell progress about the completion
    end

    def fix_stats(path, info)
      e = Digest.create_info(path)
      diff = Diff.new(e, info)
      unless e == info
        h = {}
        diff.fill_hash(nil, h, true)
        h.each do |attr,val|
          case attr
          when :mtime
           ::File.utime(info.mtime, info.mtime, path) unless info.is_a?(::ODisk::Link)
          when :owner
            owner = Etc.getpwnam(info.owner).uid
            group = Etc.getgrnam(info.group).gid
            ::File::lchown(owner, group, path)
          when :group
            owner = Etc.getpwnam(info.owner).uid
            group = Etc.getgrnam(info.group).gid
            ::File::lchown(owner, group, path)
          when :mode
            ::File::lchmod(val[1], path)
          else
            # ignore?
          end
        end
      end
    end

  end # StatFixer
end # ODisk
