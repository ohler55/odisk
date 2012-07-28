
module ODisk
  class Link < Info

    attr_accessor :target

    def initialize(name)
      super(name)
      @target = nil
    end

    def eql?(o)
      super(o) && @target == o.target
    end
    alias == eql?

  end # Link
end # ODisk
