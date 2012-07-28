
module ODisk
  class Diff
    # local Info Object
    attr_accessor :local
    # remote Info Object
    attr_accessor :remote

    attr_accessor :sub_diffs

    def self.dir_diff(l, r, recursive=false)
      ld = Digest.create(l, nil)
      rd = Digest.create(r, nil)
      diffs = digest_diff(ld, rd)
      if recursive
        lh = ld.entries_hash()
        rh = rd.entries_hash()
        keys = lh.keys | rh.keys
        keys.each do |k|
          next unless lh[k].is_a?(::ODisk::Dir) || rh[k].is_a?(::ODisk::Dir)
          unless (sd = dir_diff(::File.join(l, k), ::File.join(r, k))).nil? || sd.empty?
            if (d = diffs[k]).nil?
              d = self.new(lh[k], rh[k], sd)
            else
              d.sub_diffs = sd
            end
            diffs[k] = d
          end
        end
      end
      diffs
    end

    def self.digest_diff(ld, rd)
      diffs = {}
      lh = ld.entries_hash()
      rh = rd.entries_hash()
      keys = lh.keys | rh.keys
      keys.each do |k|
        le = lh[k]
        re = rh[k]
        diffs[k] = self.new(le, re) unless le == re
      end
      diffs
    end

    def initialize(local, remote, sub_diffs={})
      @local = local
      @remote = remote
      @sub_diffs = sub_diffs
    end

    def fill_hash(prefix, h, sym=false)
      [:class, :name, :owner, :group, :mode, :mtime, :size, :target].each do |m|
        next unless @local.respond_to?(m) and @remote.respond_to?(m)
        lv = @local.send(m)
        rv = @remote.send(m)
        if sym
          k = m
        else
          k = @local.name + '.' + m.to_s
          k = prefix + '.' + k unless prefix.nil?
        end
        h[k] = [lv, rv] unless lv == rv unless (:mtime == m && !@remote.is_a?(::ODisk::File))
      end
      pre = prefix.nil? ? @local.name : (prefix + '.' + @local.name)
      @sub_diffs.each do |name,d|
        d.fill_hash(pre, h)
      end
    end

    def to_s()
      s = ''
      h = {}
      fill_hash(nil, h)
      h.each { |k,v| s << "#{k}: #{v[0]} vs #{v[1]}\n" }
      s
    end

  end # Diff
end # ODisk
