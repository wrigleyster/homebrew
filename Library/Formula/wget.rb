require 'formula'

class Wget < Formula
  url 'ftp://ftp.gnu.org/gnu/wget/wget-1.13.4.tar.bz2'
  homepage 'http://www.gnu.org/software/wget/'
  md5 '12115c3750a4d92f9c6ac62bac372e85'

  # depends_on 'cmake'

  def install
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}", "--without-ssl"
    # system "cmake . #{std_cmake_parameters}"
    system "make install"
  end

  def test
    # This test will fail and we won't accept that! It's enough to just
    # replace "false" with the main program this formula installs, but
    # it'd be nice if you were more thorough. Test the test with
    # `brew test wget`. Remove this comment before submitting
    # your pull request!
    system "false"
  end
end
