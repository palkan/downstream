# frozen_string_literal: true

require_relative "lib/downstream/version"

Gem::Specification.new do |spec|
  spec.name = "downstream"
  spec.version = Downstream::VERSION
  spec.authors = ["merkushin.m.s@gmail.com", "dementiev.vm@gmail.com"]
  spec.summary = "Straightforward way to implement communication between Rails Engines using the Publish-Subscribe pattern"
  spec.homepage = "https://github.com/palkan/downstream"
  spec.license = "MIT"

  spec.metadata = {
    "bug_tracker_uri" => "http://github.com/palkan/downstream/issues",
    "changelog_uri" => "https://github.com/palkan/downstream/blob/master/CHANGELOG.md",
    "documentation_uri" => "http://github.com/palkan/downstream",
    "homepage_uri" => "http://github.com/palkan/downstream",
    "source_code_uri" => "http://github.com/palkan/downstream"
  }

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir.glob("lib/**/*") + %w[LICENSE.txt README.md]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 3.1"

  spec.add_dependency "after_commit_everywhere", "~> 1.0"
  spec.add_dependency "globalid", "~> 1.0"
  spec.add_dependency "rails", ">= 7"

  spec.add_development_dependency "bundler", ">= 1.16"
  spec.add_development_dependency "combustion", "~> 1.3"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rspec-rails", "~> 6.0"
end
