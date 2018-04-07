
module ODisk
  class Digest

    attr_accessor :version

    attr_accessor :entries

    attr_reader :top_path

    def self.create(top, rel_path)
      path = (rel_path.nil? || rel_path.empty?) ? top : ::File.join(top, rel_path)
      raise "#{path} is not a directory" unless ::File.directory?(path)
      d = self.new(rel_path)
      ::Dir.foreach(path) do |filename|
        next if filename.start_with?('.')
        child_path = ::File.join(path, filename)
        c = self.create_info(child_path, filename, top)
        d.entries << c
      end
      d
    end

    def self.create_info(path, filename=nil, top=nil)
      top = $local_top if top.nil?
      filename = ::File.basename(path) if filename.nil?
      begin
        stat = ::File.lstat(path)
      rescue
        return nil
      end
      if stat.directory?
        c = ::ODisk::Dir.new(filename)
      elsif stat.symlink?
        c = ::ODisk::Link.new(filename)
        c.target = ::File.readlink(path)
        c.target = c.target[top.size + 1..-1] if c.target.start_with?(top)
      elsif stat.file?
        c = ::ODisk::File.new(filename)
        c.size = stat.size()
      else
        raise "file type of #{job.path} is not supported"
      end
      c.mtime = stat.mtime()
      c.mode = stat.mode & 0777
      begin
        c.owner = Etc.getpwuid(stat.uid).name
      rescue
        c.owner = stat.uid
      end
      begin
        c.group = Etc.getgrgid(stat.gid).name
      rescue
        c.group = stat.gid
      end
      c
    end

    def initialize(top_path)
      @top_path = top_path
      @version = 0
      @entries = []
    end

    def [](name)
      @entries.each { |e| return e if name == e.name }
      nil
    end

    def empty?()
      @entries.empty?
    end

    def delete(name)
      @entries.delete_if { |e| name == e.name }
    end

    def sub_dirs()
      @entries.select { |e| e.is_a?(::ODisk::Dir) }
    end

    def entries_hash()
      h = {}
      @entries.each { |e| h[e.name] = e }
      h
    end

  end # Digest
end # ODisk
