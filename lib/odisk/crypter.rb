
module ODisk
  class Crypter < ::Opee::Actor

    def initialize(options={})
      super(options)
      @crypt_queue.ask(:ready, self)
    end
    
    def set_options(options)
      super(options)
      @crypt_queue = options[:crypt_queue]
      @copy_queue = options[:copy_queue]
      @fixer = options[:fixer]
    end

    private

    def encrypt(src, dest, remote)
      ::Opee::Env.info("encrypt \"#{src}\" into \"#{dest}\"")
      unless $dry_run
        `gpg -c --batch --yes --force-mdc --passphrase-file "#{$remote.pass_file}" -o "#{dest}" "#{src}"`
        @copy_queue.add_method(:upload, dest, remote, true)
      end
      @crypt_queue.ask(:ready, self)
    end

    def decrypt(src, dest)
      ::Opee::Env.info("decrypt \"#{src}\" into \"#{dest}\"")
      unless $dry_run
        `gpg -d --batch --yes -q --passphrase-file "#{$remote.pass_file}" -o "#{dest}" "#{src}"`
        ::File.delete(src)
        ::Opee::Env.warn("Downloaded and decrypted \"#{dest}\"")
      end
      @fixer.ask(:collect, dest, :crypter) unless @fixer.nil?
      @crypt_queue.ask(:ready, self)
    end

  end # Crypter
end # ODisk
