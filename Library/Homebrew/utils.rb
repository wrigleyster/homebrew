require 'pathname'
require 'exceptions'
require 'os'            #TODO Mac

class Tty
  class <<self
    def blue; bold 34; end
    def white; bold 39; end
    def red; underline 31; end
    def yellow; underline 33 ; end
    def reset; escape 0; end
    def em; underline 39; end
    def green; color 92 end

    def width
      `/usr/bin/tput cols`.strip.to_i
    end

  private
    def color n
      escape "0;#{n}"
    end
    def bold n
      escape "1;#{n}"
    end
    def underline n
      escape "4;#{n}"
    end
    def escape n
      "\033[#{n}m" if $stdout.tty?
    end
  end
end

# args are additional inputs to puts until a nil arg is encountered
def ohai title, *sput
  title = title.to_s[0, Tty.width - 4] unless ARGV.verbose?
  puts "#{Tty.blue}==>#{Tty.white} #{title}#{Tty.reset}"
  puts sput unless sput.empty?
end

def oh1 title
  title = title.to_s[0, Tty.width - 4] unless ARGV.verbose?
  puts "#{Tty.green}==> #{Tty.reset}#{title}"
end

def opoo warning
  puts "#{Tty.red}Warning#{Tty.reset}: #{warning}"
end

def onoe error
  lines = error.to_s.split'\n'
  puts "#{Tty.red}Error#{Tty.reset}: #{lines.shift}"
  puts lines unless lines.empty?
end


def pretty_duration s
  return "2 seconds" if s < 3 # avoids the plural problem ;)
  return "#{s.to_i} seconds" if s < 120
  return "%.1f minutes" % (s/60)
end

def interactive_shell f=nil
  unless f.nil?
    ENV['HOMEBREW_DEBUG_PREFIX'] = f.prefix
    ENV['HOMEBREW_DEBUG_INSTALL'] = f.name
  end

  fork {exec ENV['SHELL'] }
  Process.wait
  unless $?.success?
    puts "Aborting due to non-zero exit status"
    exit $?
  end
end

module Homebrew
  def self.system cmd, *args
    puts "#{cmd} #{args*' '}" if ARGV.verbose?
    fork do
      yield if block_given?
      args.collect!{|arg| arg.to_s}
      exec(cmd, *args) rescue nil
      exit! 1 # never gets here unless exec failed
    end
    Process.wait
    $?.success?
  end
end

# Kernel.system but with exceptions
def safe_system cmd, *args
  unless Homebrew.system cmd, *args
    args = args.map{ |arg| arg.to_s.gsub " ", "\\ " } * " "
    raise ErrorDuringExecution, "Failure while executing: #{cmd} #{args}"
  end
end

# prints no output
def quiet_system cmd, *args
  Homebrew.system(cmd, *args) do
    $stdout.close
    $stderr.close
  end
end

def curl *args
  curl = Pathname.new '/usr/bin/curl'
  raise "#{curl} is not executable" unless curl.exist? and curl.executable?

  args = [HOMEBREW_CURL_ARGS, HOMEBREW_USER_AGENT, *args]
  # See https://github.com/mxcl/homebrew/issues/6103
  if Os.flavour.equal? :mac                     #TODO Mac
    args << "--insecure" if MacOS.version < 10.6
  end

  safe_system curl, *args
end

def puts_columns items, star_items=[]
  return if items.empty?

  if star_items && star_items.any?
    items = items.map{|item| star_items.include?(item) ? "#{item}*" : item}
  end

  if $stdout.tty?
    # determine the best width to display for different console sizes
    console_width = `/bin/stty size`.chomp.split(" ").last.to_i
    console_width = 80 if console_width <= 0
    longest = items.sort_by { |item| item.length }.last
    optimal_col_width = (console_width.to_f / (longest.length + 2).to_f).floor
    cols = optimal_col_width > 1 ? optimal_col_width : 1

    IO.popen("/usr/bin/pr -#{cols} -t -w#{console_width}", "w"){|io| io.puts(items) }
  else
    puts items
  end
end

def exec_editor *args
  return if args.to_s.empty?

  editor = ENV['HOMEBREW_EDITOR'] || ENV['EDITOR']
  if editor.nil?
    editor = if system "/usr/bin/which -s mate"          #TODO Mac -- Textmate/BBEdit/TextWrangler/etc.
      'mate'
    elsif system "/usr/bin/which -s edit"
      'edit' # BBEdit / TextWrangler
    else
      '/usr/bin/vim' # Default to vim
    end
  end

  # Invoke bash to evaluate env vars in $EDITOR
  # This also gets us proper argument quoting.
  # See: https://github.com/mxcl/homebrew/issues/5123
  system "bash", "-c", editor + ' "$@"', "--", *args
end

# GZips the given paths, and returns the gzipped paths
def gzip *paths
  paths.collect do |path|
    system "/usr/bin/gzip", path
    Pathname.new("#{path}.gz")
  end
end

module ArchitectureListExtension                        #TODO Mac
  def universal?
    self.include? :i386 and self.include? :x86_64
  end

  def remove_ppc!
    self.delete :ppc7400
    self.delete :ppc64
  end

  def as_arch_flags
    self.collect{ |a| "-arch #{a}" }.join(' ')
  end
end

# Returns array of architectures that the given command or library is built for.
def archs_for_command cmd
  cmd = cmd.to_s # If we were passed a Pathname, turn it into a string.
  cmd = `/usr/bin/which #{cmd}` unless Pathname.new(cmd).absolute?
  cmd.gsub! ' ', '\\ '  # Escape spaces in the filename.

  lines = `/usr/bin/file -L #{cmd}`
  archs = lines.to_a.inject([]) do |archs, line|                  #TODO Mac
    case line
    when /Mach-O (executable|dynamically linked shared library) ppc/
      archs << :ppc7400
    when /Mach-O 64-bit (executable|dynamically linked shared library) ppc64/
      archs << :ppc64
    when /Mach-O (executable|dynamically linked shared library) i386/
      archs << :i386
    when /ELF 32-bit LSB (shared object|executable), .*?386/
      archs << :i386
    when /ELF 64-bit LSB (shared object|executable), x86_64/
      archs << :x86_64
    when /Mach-O 64-bit (executable|dynamically linked shared library) x86_64/
      archs << :x86_64
    else
      archs
    end
  end
  archs.extend(ArchitectureListExtension)
end

def inreplace path, before=nil, after=nil
  [*path].each do |path|
    f = File.open(path, 'r')
    s = f.read

    if before == nil and after == nil
      s.extend(StringInreplaceExtension)
      yield s
    else
      s.gsub!(before, after)
    end

    f.reopen(path, 'w').write(s)
    f.close
  end
end

def ignore_interrupts
  std_trap = trap("INT") {}
  yield
ensure
  trap("INT", std_trap)
end

def nostdout
  if ARGV.verbose?
    yield
  else
    begin
      require 'stringio'
      real_stdout = $stdout
      $stdout = StringIO.new
      yield
    ensure
      $stdout = real_stdout
    end
  end
end

case Os.flavour                               #TODO Mac
  when :mac
    require 'os/mac'
  when :linux
    require 'os/linux'
end

module GitHub extend self
  def issues_for_formula name
    # bit basic as depends on the issue at github having the exact name of the
    # formula in it. Which for stuff like objective-caml is unlikely. So we
    # really should search for aliases too.

    name = f.name if Formula === name

    require 'open-uri'
    require 'yaml'

    issues = []

    open "http://github.com/api/v2/yaml/issues/search/mxcl/homebrew/open/#{name}" do |f|
      yaml = YAML::load(f.read);
      yaml['issues'].each do |issue|
        # don't include issues that just refer to the tool in their body
        if issue['title'].include? name
          issues << issue['html_url']
        end
      end
    end

    issues
  rescue
    []
  end
end
