# S3mirror

S3mirror is a very simple class that help you mirror uploaded files to other s3-compatible services, let's say for example your main file storage is AWS S3 and you want each time you upload a file to mirror that file to another S3-compatible storage like Digital Ocean Spaces, this gem will help you do that!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 's3mirror'
```

And then execute:

    $ bundle install


## Usage

First create an initializer file in config/initializers/s3mirror.rb

```
S3mirror::Mirror.configure do |config|
  # temp_download_folder is optional: where the main file will be downloaded temporarily (by default the file to mirror will be downloaded to you rails app tmp folder)
  # config.temp_download_folder = '/tmp'

  config.s3_main = { # primary s3 service details
    region: ENV["AWS_REGION"],
    endpoint: ENV["AWS_ENDPOINT"],
    access_key_id: ENV["AWS_ACCESS_KEY_ID"],
    secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
    bucket_name: ENV["AWS_BUCKET_NAME"]
  }

  config.s3_mirrors = [ # mirrors s3 services details (at lest 1 mirror should be provided)
    {
      region: ENV["MIRROR1_REGION"],
      endpoint: ENV["MIRROR1_ENDPOINT"],
      access_key_id: ENV["MIRROR1_ACCESS_KEY_ID"],
      secret_access_key: ENV["MIRROR1_SECRET_ACCESS_KEY"],
      bucket_name: ENV["MIRROR1_BUCKET_NAME"]
    },
    {
      region: ENV["MIRROR2_REGION"],
      endpoint: ENV["MIRROR2_ENDPOINT"],
      access_key_id: ENV["MIRROR2_ACCESS_KEY_ID"],
      secret_access_key: ENV["MIRROR2_SECRET_ACCESS_KEY"],
      bucket_name: ENV["MIRROR2_BUCKET_NAME"]
    },
    {
      # YOU CAN SETUP MORE MIRRORS IF NEEDED
    }
  ]
end

```

When you upload a file/image etc, just create an instance of S3mirror::Mirror and pass the object "key" to it by calling the method "mirror":

```
key = '123e4567-e89b-12d3-a456-426614174000/image.jpg' # key of the object you want to mirror

s3mirror = S3mirror::Mirror.new()
result = s3mirror.mirror(key)
```

Because S3mirror will download/upload your file(s) from/to third party s3 services, it's very recommended to call it within a background job

```
rails g job s3mirror
```

This will generate s3mirror_job.rb file under jobs folder:

```
class S3mirrorJob < ApplicationJob
  queue_as :default

  def perform(key)

    s3mirror = S3mirror::Mirror.new()
    result = s3mirror.mirror(key)

    mirrored_now = result[:mirrored_now] # in case of retries, s3mirror will mirror only the failed ones, mirrored_now describe the count of successful mirrored files at a given request/try.

    total_mirrored = result[:total_mirrored]

    total_failed = result[:total_failed]

    # do something with result (i.e: update database "mirrored field" to true once total_failed is 0)

  end

end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/scratchoo/s3mirror.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
