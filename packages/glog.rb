module STARMAN
  class Glog < Package
    homepage 'https://github.com/google/glog'
    url 'https://github.com/google/glog/archive/v0.3.4.tar.gz'
    sha256 'ce99d58dce74458f7656a68935d7a0c048fa7b4626566a71b7f4e545920ceb10'
    version '0.3.4'

    depends_on :gflags

    def install
      run './configure', '--disable-dependency-tracking',
                          "--prefix=#{prefix}"
      run 'make', 'install'
    end
  end
end
