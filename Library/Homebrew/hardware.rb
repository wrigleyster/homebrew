class Hardware
  # These methods use info spewed out by sysctl.
  # Look in <mach/machine.h> for decoding info.

  def self.cpu_type
    case Os.flavour
      when :linux
        :intel
      when :mac          #TODO Mac
        @@cpu_type ||= `/usr/sbin/sysctl -n hw.cputype`.to_i

        case @@cpu_type
          when 7
            :intel
          when 18
            :ppc
          else
            :dunno
        end
      else

    end
  end

  def self.intel_family
    case Os.flavour
      when :linux
        @@intel_family ||= 0x1337
      when :mac            #TODO Mac
        @@intel_family ||= `/usr/sbin/sysctl -n hw.cpufamily`.to_i
    end


    case @@intel_family
    when 0x73d67300 # Yonah: Core Solo/Duo
      :core
    when 0x426f69ef # Merom: Core 2 Duo
      :core2
    when 0x78ea4fbc # Penryn
      :penryn
    when 0x6b5a4cd2 # Nehalem
      :nehalem
    when 0x573B5EEC # Arrandale
      :arrandale
    when 0x5490B78C
      :sandybridge # Sandy bridge
    else
      :dunno
    end
  end

  def self.processor_count       #TODO Mac
    case Os.flavour
      when :linux
        @@processor_count ||= `grep -c processor /proc/cpuinfo`.to_i
      when :mac
        @@processor_count ||= `/usr/sbin/sysctl -n hw.ncpu`.to_i
      else
        abort "Could not determine processor count."
    end
  end
  
  def self.cores_as_words
    case Hardware.processor_count
    when 1 then 'single'
    when 2 then 'dual'
    when 4 then 'quad'
    else
      Hardware.processor_count
    end
  end

  def self.is_32_bit?
    not self.is_64_bit?
  end

  def self.is_64_bit?       #TODO Mac
    case Os.flavour
      when :linux
        `uname -p` == "x86_64"
      when :mac
        self.sysctl_bool("hw.cpu64bit_capable")
      else
        abort "Could not determine processor capabilities."
    end
  end
  
  def self.bits
    Hardware.is_64_bit? ? 64 : 32
  end

protected
  def self.sysctl_bool(property)
    result = nil
    IO.popen("/usr/sbin/sysctl -n #{property} 2>/dev/null") do |f|        #TODO Mac
      result = f.gets.to_i # should be 0 or 1
    end
    $?.success? && result == 1 # sysctl call succeded and printed 1
  end
end
