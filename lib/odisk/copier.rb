begin
  v = $VERBOSE
  $VERBOSE = false
  require 'net/ssh'
  require 'net/sftp'
  $VERBOSE = v
end

module ODisk
  # Provides upload and download functionality using sftp and ssh on a single connection.
  class Copier < ::Opee::Actor

    def initialize(options={})
      @ftp = nil
      @ssh = nil
      super(options)
      @copy_queue.ask(:ready, self)
    end
    
    def set_options(options)
      super(options)
      @copy_queue = options[:copy_queue]
      @crypt_queue = options[:crypt_queue]
      @fixer = options[:fixer]
    end

    def close()
      @ftp.close_channel() unless @ftp.nil?
      @ftp = nil
      @ssh.close() unless @ssh.nil?
      super()
    end

    private

    def upload(local, remote, delete_after=false)
      ::Opee::Env.info("upload \"#{local}\" to \"#{remote}\"#{delete_after ? ' then delete' : ''}")
      unless $dry_run
        @ftp = Net::SFTP.start($remote.host, $remote.user) if @ftp.nil?
        begin
          @ftp.upload!(local, remote)
          `rm "#{local}"` if delete_after
          ::Opee::Env.warn("Uploaded \"#{local}\"")
        rescue Net::SFTP::StatusException => e
          if Net::SFTP::Constants::StatusCodes::FX_NO_SUCH_FILE == e.code
            begin
              assure_dirs_exist(::File.dirname(remote))
              retry
            rescue Exception => e2
              ::Opee::Env.error("Upload of \"#{local}\" failed: #{e2.class}: #{e2.message}")
            end
          else
            ::Opee::Env.error("Upload of \"#{local}\" failed: #{e.class}: (#{e.code}) #{e.description}\n #{e.text}\n #{e.response}")
          end
        end
      end
      @copy_queue.ask(:ready, self)
    end

    def download(remote, local, decrypt_path=nil)
      ::Opee::Env.info("download #{remote} to #{local}")
      @ftp = Net::SFTP.start($remote.host, $remote.user) if @ftp.nil?
      begin
        @ftp.download!(remote, local)
        if decrypt_path.nil?
          @fixer.ask(:collect, local, :copier) unless @fixer.nil?
          ::Opee::Env.warn("Downloaded \"#{local}\"")
        else
          @crypt_queue.add_method(:decrypt, local, decrypt_path)
        end
      rescue Exception => e
        ::Opee::Env.error("Download of \"#{local}\" failed: #{e.class}: #{e.message}")
        #::Opee::Env.rescue(e)
      end
      @copy_queue.ask(:ready, self)
    end

    def remove_local(path)
      `rm -rf "#{path}"` unless $dry_run
      ::Opee::Env.warn("Removed local \"#{path}\"")
    end

    def remove_remote(path)
      unless $dry_run
        @ssh = Net::SSH.start($remote.host, $remote.user) if @ssh.nil?
        out = @ssh.exec!(%{rm -rf "#{path}" "#{path}.gpg"})
        raise out unless out.nil? || out.strip().empty?
      end
      ::Opee::Env.warn("Removed remote \"#{path}\"")
    end

    def assure_dirs_exist(dir)
      ::Opee::Env.info("creating remote dir \"#{dir}\"")
      unless $dry_run
        @ssh = Net::SSH.start($remote.host, $remote.user) if @ssh.nil?
        out = @ssh.exec!(%{mkdir -p "#{dir}"})
        raise 'Remote ' + out unless out.nil? || out.strip().empty?
      end
    end

  end # Copier
end # ODisk
