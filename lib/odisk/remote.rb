
module ODisk
  # Just a way to keep the data associated with a remote site together one
  # Object.
  class Remote
    attr_accessor :user
    attr_accessor :host
    attr_accessor :dir
    attr_accessor :pass_file

    def initialize()
      @user = nil
      @host = nil
      @dir = nil
      @pass_file = nil
    end

    # Expects a string as input of the form user@remote.com:dir:passphrase_file
    def update(str)
      u, x = str.strip().split('@')
      h, t, p = x.split(':')
      @user = u if @user.nil? && u.is_a?(String) && !u.empty?
      @host = h if @host.nil? && h.is_a?(String) && !h.empty?
      @dir = t if @dir.nil? && t.is_a?(String) && !t.empty?
      @pass_file = p if @pass_file.nil? && p.is_a?(String) && !p.empty?
    end

    def complete?()
      !(@user.nil? || @host.nil? || @dir.nil? || @pass_file.nil?)
    end

    def okay?()
      !(@user.nil? || @host.nil? || @dir.nil?)
    end

    def encrypt?()
      !@pass_file.nil?
    end

    def to_s()
      "#{user}@#{host}:#{@dir}:#{@pass_file}"
    end

  end # Remote
end # ODisk
