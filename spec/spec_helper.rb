# frozen_string_literal: true

require "bundler/setup"
require "debug"
require "rspec"

require "combustion"
Combustion.initialize! :active_record, :action_controller, :active_job do
  config.logger = Logger.new(nil)
  config.log_level = :fatal
  config.active_job.queue_adapter = :test
  config.server_timing = true
end

require "rspec/rails"
require "downstream/rspec"

Downstream.configure do |config|
  config.pubsub = :stateless
end

require_relative "support/test_events"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.run_all_when_everything_filtered = true

  config.after(:each) do
    # Clear ActiveJob jobs
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    ActiveJob::Base.queue_adapter.performed_jobs.clear
  end
end
