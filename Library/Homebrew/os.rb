class Os
  def self.flavour
    @@flavour ||= `uname -s`
    case @@flavour
      when /^Linux/
        :linux
      when /^Darwin/
        :mac
      else
        :dunno
    end
  end

  def self.is_ubuntu?
    return false if not flavour == :linux
    if system "test -f /etc/lsb-release"
      system "grep Ubuntu /etc/lsb-release>/dev/null"
    end
  end

  def self.full_version
    case flavour
      when :linux
         `uname -v`   #TODO
      when :mac
        `/usr/sbin/sysctl -n hw.cpufamily`.to_i
    end
  end

  def self.name
    case flavour
      when :linux
        `uname -o` #TODO
      when :mac
        "Mac OS X"
    end
  end
end