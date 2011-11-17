module Linux extend self
  def version
    "N/A"
  end
  def default_cc
    Pathname.new("/usr/bin/cc").realpath.basename.to_s
  end
  def default_compiler
    case default_cc
      when /^gcc/ then :gcc
      when /^llvm/ then :llvm
      when "clang" then :clang
      else :gcc # a hack, but a sensible one prolly
    end
  end
#      def gcc_42_build_version
#      def gcc_40_build_version
#      def xcode_prefix
#      def xcode_version
      def x11_installed?
        Pathname.new('/usr/bin/X').exist?
      end
      def macports_or_fink_installed?
        false
      end
      def leopard?
        abort "Somewhere a check for leopard occured. This is Linux, you won't spot a leopard here."
      end
      def snow_leopard?
        abort "Somewhere a check for snow leopard occured. This is Linux, the peguin."
      end
      def lion?
        abort "Somewhere a check for lion occured. This is Linux, where penguins lie on the snow"
      end
  def prefer_64_bit?
    Hardware.is_64_bit?
  end
end