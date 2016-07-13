module STARMAN
  class Boost < Package
    homepage 'http://www.boost.org/'
    url 'http://heanet.dl.sourceforge.net/project/boost/boost/1.61.0/boost_1_61_0.tar.bz2'
    sha256 'a547bd06c2fd9a71ba1d169d9cf0339da7ebf4753849a8f7d6fdb8feee99b640'
    version '1.61.0'

    option 'with-mpi', {
      desc: 'Build with parallel support.',
      accept_value: { boolean: false }
    }
    option 'with-single', {
      desc: 'Enable building single-threading variant.',
      accept_value: { boolean: true }
    }
    option 'with-static', {
      desc: 'Enable building static library variant.',
      accept_value: { boolean: false }
    }

    depends_on :icu4c
    depends_on :mpi if with_mpi?

    def toolset
      compiler = CompilerStore.compiler(:cxx)
      return @toolset if @toolset
      case compiler.vendor
      when :intel
        if compiler.version <= '11.1'
          CLI.report_error 'Intel compiler is too old to compile Boost! See ' +
            'https://software.intel.com/en-us/articles/boost-1400-compilation-error-while-building-with-intel-compiler/'
        end
        if OS.mac?
          @toolset = 'intel-darwin'
        elsif OS.linux?
          @toolset = 'intel-linux'
        end
      when :gnu
        if OS.mac?
          @toolset = 'darwin'
        elsif OS.linux?
          @toolset = 'gcc'
        end
      when :llvm
        @toolset = 'clang'
      end
      @toolset
    end

    def install
      FileUtils.write 'user-config.jam' do |content|
        content << "using #{toolset} : : #{ENV['CXX']} ;\n"
        content << "using mpi ;\n" if with_mpi?
      end

      args = %W[
        --prefix=#{prefix}
        --libdir=#{lib}
        --with-icu=#{Icu4c.prefix}
      ]
      without_libraries = ['python']
      without_libraries << 'mpi' if not with_mpi?
      without_libraries << 'log' if CompilerStore.compiler(:cxx).vendor == :llvm
      args << "--without-libraries=#{without_libraries.join(',')}"
      run './bootstrap.sh', *args

      args = %W[
        --prefix=#{prefix}
        --libdir=#{lib}
        --d2
        --j#{CommandLine.options[:'make-jobs'].value}
        --layout=tagged
        --user-config=user-config.jam
        install
      ]
      if with_single?
        args << 'threading=multi,single'
      else
        args << 'threading=multi'
      end
      if with_static?
        args << 'link=shared,static'
      else
        args << 'link=shared'
      end
      args << 'cxxflags=-std=c++11'
      args << 'cxxflags=-stdlib=libc++' << 'linkflags=-stdlib=libc++' if CompilerStore.compiler(:cxx).vendor == :llvm
      run './b2', 'headers'
      run './b2', *args
    end
  end
end
