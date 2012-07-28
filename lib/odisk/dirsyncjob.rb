
module ODisk
  class DirSyncJob < ::Opee::Job

    # relative path from top
    attr_reader :path
    # only set by the Digester
    attr_accessor :current_digest
    # only set by the SyncStarter
    attr_accessor :previous_digest
    # only set by the Fetcher
    attr_accessor :remote_digest
    # new digest to be set locally and remotely
    attr_accessor :new_digest

    def initialize(path)
      @path = path
      @current_digest = nil
      @previous_digest = nil
      @remote_digest = nil
      @new_digest = nil
    end
    
  end # DirSyncJob
end # ODisk
