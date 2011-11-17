require 'os/linux'
require 'os/mac'

class Os
  def self.flavour
    @@flavour ||= `uname -s`.chomp
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

  def self.mac?
    flavour.equal? :mac
  end

  def self.linux?
    flavour.equal? :linux
  end

  def self.full_version
    case flavour
      when :linux
         `uname -v`.chomp   #TODO
      when :mac
        `/usr/sbin/sysctl -n hw.cpufamily`.to_i
    end
  end

  def self.name
    case flavour
      when :linux
        `uname -o`.chomp #TODO
      when :mac
        "Mac OS X"
    end
  end
end