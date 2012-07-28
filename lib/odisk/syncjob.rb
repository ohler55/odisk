
module ODisk
  class SyncJob < ::Opee::Job

    STATS  = 0
    REMOVE = 1
    COPY   = 2
    
    # location of master
    OREFS  = 0 # encrypted master
    LOCAL  = 1
    REMOTE = 2

    attr_reader :path
    attr_reader :master
    attr_reader :op

    def initialize(rel_path, master, op)
      @path = rel_path
      @master = master
      @op = op
    end

  end # SyncJob
end # ODisk
