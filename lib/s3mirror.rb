require "s3mirror/version"
require "s3mirror/configuration"

# usage:
# s3mirror = S3mirror::Mirror.new({})
module S3mirror
  class Error < StandardError; end

  class Mirror

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.configure(&block)
      yield(configuration)
    end

    def initialize(options={})
      @temp_destination = Mirror.configuration.temp_download_folder #options.delete(:temp_download_folder)

      if !@temp_destination.blank? && !Pathname.new(@temp_destination).absolute?
        throw 'temp_download_folder should be an absolute path'
      end

      @s3_main = Mirror.configuration.s3_main #options.delete(:s3_main)
      @s3_mirrors = Mirror.configuration.s3_mirrors #options.delete(:s3_mirrors)
    end

    def get_s3_bucket(service)
      # create a client that will be used by resource, this help switching between different s3 providers without changing default configuration set in initializer (i.e: Aws.config.update({...}))
      client = Aws::S3::Client.new(
        endpoint: service[:endpoint],
        region: service[:region],
        credentials: Aws::Credentials.new(service[:access_key_id], service[:secret_access_key])
      )
      # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Resource.html
      # if client not supplied, default configuration will be used
      s3 = Aws::S3::Resource.new(client: client)
      return s3.bucket(service[:bucket_name])
    end

    def mirror(key)
      unique_prefix = 't' + (Time.now.to_f * 1000000).to_s

      # filename is the name of file used for our download
      filename = File.basename(key)

      # add a temporary unique prefix to the filename to prevent collision (i.e: 2 downloaded file with same name)
      prefixed_filename = "#{unique_prefix}_#{filename}"

      # all files will be downloaded to your app "tmp" folder (otherwise the specified @temp_destination), the unique prefix above will guarantee uniqueness of files names
      if @temp_destination.blank?
        file_path = Rails.root.join('tmp', prefixed_filename)
      else
        file_path = File.join(@temp_destination, prefixed_filename)
      end

      uploaded_now = 0 # uploaded count for the current mirroring try
      uploaded_total = 0

      if download(key, file_path)
        begin
          @s3_mirrors.each do |mirror|
            mirror_bucket = get_s3_bucket(mirror)
            if !mirror_has_file?(key, mirror_bucket)
              uploaded = upload(file_path, key, mirror_bucket)
              if uploaded
                uploaded_now += 1
                uploaded_total += 1
              end
            else
              uploaded_total += 1
            end
          end
        ensure
          # remove downloaded file
          File.delete(file_path)
        end
      else
        # throw 'file not downloaded!!'
      end

      return {
        mirrored_now: uploaded_now,
        total_mirrored: uploaded_total,
        total_failed: @s3_mirrors.size - uploaded_total
      }
    end

    # get object from main/primary s3 service
    def s3_object(key)
      bucket = get_s3_bucket(@s3_main)
      bucket.object(key)
    end

    # read note (1) below
    def download(key, destination_on_desk)
      # returns true if downloaded successfully
      begin
        s3_object(key).download_file(destination_on_desk)
      rescue Aws::S3::Errors::NoSuchKey
        return false
      end
    end

    # read note (2) below
    def upload(file_path, file_key, mirror_bucket)
      object_name = file_key
      # create empty object in the mirror bucket with same name as the original file.
      object = mirror_bucket.object(object_name)
      # upload file to that object.
      object.upload_file(file_path) # return true if uploaded successfully)
    end

    def mirror_has_file?(file_key, mirror_bucket)
      begin
        object = mirror_bucket.object(file_key)
        if object.exists?
          true
        else
          false
        end
      rescue Aws::S3::Errors::NotFound
        false
      end
    end

  end

end
