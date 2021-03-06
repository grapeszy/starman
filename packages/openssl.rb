module STARMAN
  class Openssl < Package
    homepage 'https://openssl.org/'
    url 'https://www.openssl.org/source/openssl-1.0.2h.tar.gz'
    sha256 '1d4007e53aad94a5b2002fe045ee7bb0b3d98f1a47f8b2bc851dcd1c74332919'
    version '1.0.2h'
    language :c

    compatible_with '10.11' if OS.mac? and OS.version =~ '10.12'

    option 'x86-64', {
      desc: 'Build x86-64 library.',
      accept_value: { boolean: true }
    }

    depends_on :zlib

    def arch_flags
      if OS.mac?
        { x86_64: 'darwin64-x86_64-cc', i386: 'darwin-i386-cc' }
      elsif OS.linux?
        { x86_64: 'linux-x86_64', i386: 'linux-x32' }
      end
    end

    def install
      args = %W[
        --prefix=#{prefix}
        --openssldir=#{etc}/openssl
        zlib-dynamic
        shared
        enable-cms
      ]
      args << 'enable-ec_nistp_64_gcc_128' # Needs C compiler to support __uint128_t.
      inreplace 'crypto/comp/c_zlib.c',
        'zlib_dso = DSO_load(NULL, "z", NULL, 0);',
        "zlib_dso = DSO_load(NULL, \"#{Zlib.lib}/libz.#{OS.soname}\", NULL, DSO_FLAG_NO_NAME_TRANSLATION);"
      run './Configure', *args, arch_flags[x86_64? ? :x86_64 : :i386]
      inreplace 'Makefile', {
        /^ZLIB_INCLUDE=/ => "ZLIB_INCLUDE=#{Zlib.inc}",
        /^LIBZLIB=/ => "LIBZLIB=#{Zlib.lib}"
      }
      run 'make'
      run 'make', 'test' if not skip_test?
      run 'make', 'install'
    end

    def post_install
      valid_certs = []
      if OS.mac?
        keychains = %w[
          /System/Library/Keychains/SystemRootCertificates.keychain
        ]

        certs_list = `security find-certificate -a -p #{keychains.join(" ")}`
        certs = certs_list.scan(
          /-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----/m
        )

        valid_certs = certs.select do |cert|
          IO.popen("#{bin}/openssl x509 -inform pem -checkend 0 -noout", "w") do |openssl_io|
            openssl_io.write(cert)
            openssl_io.close_write
          end
          $?.success?
        end
      end
      mkdir_p "#{etc}/openssl"
      write_file "#{etc}/openssl/cert.pem", valid_certs.join("\n")
    end
  end
end
