begin
  require 'qiniu'
  QINIU_AVAILABLE = true
rescue LoadError
  QINIU_AVAILABLE = false
end

module STARMAN
  class QiniuAdapter
    extend System::Command

    Bucket = 'starman'.freeze
    DownloadDomain = 'http://7xuddd.com1.z0.glb.clouddn.com'

    def self.init
      if ENV['STARMAN_QINIU_ACCESSKEY'] and not ENV['STARMAN_QINIU_ACCESSKEY'].empty? and
         ENV['STARMAN_QINIU_SECRETKEY'] and not ENV['STARMAN_QINIU_SECRETKEY'].empty? and
         QINIU_AVAILABLE
        Qiniu.establish_connection! :access_key => ENV['STARMAN_QINIU_ACCESSKEY'],
                                    :secret_key => ENV['STARMAN_QINIU_SECRETKEY']
        @@connection_established = true
      else
        @@connection_established = false
      end
    end

    def self.uploaded? package
      tar_name = Storage.tar_name package
      if QINIU_AVAILABLE and @@connection_established
        code, result = Qiniu::Storage.stat(Bucket, tar_name)
        code == 200
      else
        CLI.report_error 'You have no permission to upload package!'
      end
    end

    def self.upload! package
      tar_name = Storage.tar_name package
      # Compress built package.
      CLI.report_notice "Compress package #{CLI.blue package.name}."
      tar package.prefix, "#{ConfigStore.package_root}/#{tar_name}"
      # Upload to Qiniu.
      CLI.report_notice "Upload package #{CLI.blue package.name}."
      put_policy = Qiniu::Auth::PutPolicy.new(Bucket, tar_name, 3600)
      uptoken = Qiniu::Auth.generate_uptoken(put_policy)
      code, result = Qiniu::Storage.upload_with_token_2(
        uptoken, "#{ConfigStore.package_root}/#{tar_name}", tar_name, nil,
        bucket: Bucket)
      raise result['error'] if code != 200
    end

    def self.delete! package
      tar_name = Storage.tar_name package
      code, result = Qiniu::Storage.delete(Bucket, tar_name)
      raise result['error'] if code != 200
    end

    def self.download package
      tar_name = Storage.tar_name package
      url = "#{DownloadDomain}/#{tar_name}"
      curl url, ConfigStore.package_root
    end
  end
end
