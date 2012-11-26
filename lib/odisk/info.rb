
module ODisk
  class Info

    NORMAL = 0 # or nil
    ERROR  = 1
    REMOTE = 2
    LOCAL  = 3

    attr_accessor :name
    attr_accessor :owner
    attr_accessor :group
    attr_accessor :mode
    attr_accessor :mtime
    attr_accessor :master
    attr_accessor :removed

    def initialize(name)
      @name = name
      @owner = nil
      @group = nil
      @mode = 0
      @mtime = nil
      @master = nil
      @removed = false
    end

    def eql?(o)
      return false unless o.class == self.class
      # don't check master flag
      (@name == o.name &&
       @owner == o.owner &&
       (@group == o.group || $group_tolerant) &&
       @mode == o.mode &&
       @removed == o.removed)
    end
    alias == eql?

  end # Info
end # ODisk
