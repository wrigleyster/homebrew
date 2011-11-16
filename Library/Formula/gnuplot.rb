require 'formula'

class Gnuplot < Formula
  url 'http://downloads.sourceforge.net/project/gnuplot/gnuplot/4.4.3/gnuplot-4.4.3.tar.gz'
  homepage 'http://www.gnuplot.info'
  md5 '639603752996f4923bc02c895fa03b45'

  # depends_on 'cmake'

  def install
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    # system "cmake . #{std_cmake_parameters}"
    system "make install"
  end

  def test
    # This test will fail and we won't accept that! It's enough to just
    # replace "false" with the main program this formula installs, but
    # it'd be nice if you were more thorough. Test the test with
    # `brew test gnuplot`. Remove this comment before submitting
    # your pull request!
    system "false"
  end
end
