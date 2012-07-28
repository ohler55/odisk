
module ODisk
  class StatJob < ::Opee::Job

    attr_reader :path
    attr_reader :mods
    attr_accessor :digest

    def initialize(path, digest)
      @path = path
      @digest = digest
      @mods = []
    end

    def add_mod(name)
      @mods << name
    end

    def key()
      @path
    end

    def complete?(token)
      @mods.empty?
    end

    def to_s()
      "<StatJob:#{@path} [#{@mods.join(',')}]>"
    end

  end # StatJob
end # ODisk
