module MacOS extend self
  def version
    MACOS_VERSION
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

  def gcc_42_build_version
    `/usr/bin/gcc-4.2 -v 2>&1` =~ /build (\d{4,})/
    if $1
      $1.to_i
    elsif system "/usr/bin/which gcc"
      # Xcode 3.0 didn't come with gcc-4.2
      # We can't change the above regex to use gcc because the version numbers
      # are different and thus, not useful.
      # FIXME I bet you 20 quid this causes a side effect — magic values tend to
      401
    else
      nil
    end
  end

  def gcc_40_build_version
    `/usr/bin/gcc-4.0 -v 2>&1` =~ /build (\d{4,})/
    if $1
      $1.to_i
    else
      nil
    end
  end

  # usually /Developer
  def xcode_prefix
    @xcode_prefix ||= begin
      path = `/usr/bin/xcode-select -print-path 2>&1`.chomp
      path = Pathname.new path
      if path.directory? and path.absolute?
        path
      elsif File.directory? '/Developer'
        # we do this to support cowboys who insist on installing
        # only a subset of Xcode
        Pathname.new '/Developer'
      else
        nil
      end
    end
  end

  def xcode_version
    @xcode_version ||= begin
      raise unless system "/usr/bin/which -s xcodebuild"
      `xcodebuild -version 2>&1` =~ /Xcode (\d(\.\d)*)/
      raise if $1.nil?
      $1
    rescue
      # for people who don't have xcodebuild installed due to using
      # some variety of minimal installer, let's try and guess their
      # Xcode version
      case llvm_build_version.to_i
      when 0..2063 then "3.1.0"
      when 2064..2065 then "3.1.4"
      when 2366..2325
        # we have no data for this range so we are guessing
        "3.2.0"
      when 2326
        # also applies to "3.2.3"
        "3.2.4"
      when 2327..2333 then "3.2.5"
      when 2335
        # this build number applies to 3.2.6, 4.0 and 4.1
        # https://github.com/mxcl/homebrew/wiki/Xcode
        "4.0"
      else
        "4.2"
      end
    end
  end

  def llvm_build_version
    # for Xcode 3 on OS X 10.5 this will not exist
    # NOTE may not be true anymore but we can't test
    @llvm_build_version ||= if File.exist? "/usr/bin/llvm-gcc"
      `/usr/bin/llvm-gcc -v 2>&1` =~ /LLVM build (\d{4,})/
      $1.to_i
    end
  end

  def x11_installed?
    Pathname.new('/usr/X11/lib/libpng.dylib').exist?
  end

  def macports_or_fink_installed?
    # See these issues for some history:
    # http://github.com/mxcl/homebrew/issues/#issue/13
    # http://github.com/mxcl/homebrew/issues/#issue/41
    # http://github.com/mxcl/homebrew/issues/#issue/48

    %w[port fink].each do |ponk|
      path = `/usr/bin/which -s #{ponk}`
      return ponk unless path.empty?
    end

    # we do the above check because macports can be relocated and fink may be
    # able to be relocated in the future. This following check is because if
    # fink and macports are not in the PATH but are still installed it can
    # *still* break the build -- because some build scripts hardcode these paths:
    %w[/sw/bin/fink /opt/local/bin/port].each do |ponk|
      return ponk if File.exist? ponk
    end

    # finally, sometimes people make their MacPorts or Fink read-only so they
    # can quickly test Homebrew out, but still in theory obey the README's
    # advise to rename the root directory. This doesn't work, many build scripts
    # error out when they try to read from these now unreadable directories.
    %w[/sw /opt/local].each do |path|
      path = Pathname.new(path)
      return path if path.exist? and not path.readable?
    end

    false
  end

  def leopard?
    10.5 == MACOS_VERSION
  end

  def snow_leopard?
    10.6 <= MACOS_VERSION # Actually Snow Leopard or newer
  end

  def lion?
    10.7 <= MACOS_VERSION #Actually Lion or newer
  end

  def prefer_64_bit?
    Hardware.is_64_bit? and 10.6 <= MACOS_VERSION
  end
end
