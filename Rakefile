# frozen_string_literal: true

require "bundler/setup"
require "downstream"
require_relative "spec/rails_helper"

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end
