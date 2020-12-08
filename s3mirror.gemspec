require_relative 'lib/s3mirror/version'

Gem::Specification.new do |spec|
  spec.name          = "s3mirror"
  spec.version       = S3mirror::VERSION
  spec.authors       = ["scratchoo"]
  spec.email         = ["support@scratchoo.com"]

  spec.summary       = %q{Mirror your file to s3 compatible services after uploading it.}
  spec.description   = %q{S3mirror allows you to copy an uploaded file to mirror(s) which are basically any s3 compatible storage.}
  spec.homepage      = "https://github.com/scratchoo/s3mirror"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/scratchoo/s3mirror"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'aws-sdk-s3'

end
