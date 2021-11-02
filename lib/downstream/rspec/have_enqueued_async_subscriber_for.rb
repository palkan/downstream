# frozen_string_literal: true

require "rspec/rails/matchers/active_job"

module Downstream
  class HaveEnqueuedAsyncSubscriberFor < RSpec::Rails::Matchers::ActiveJob::HaveEnqueuedJob
    class EventMatcher
      include ::RSpec::Matchers::Composable

      attr_reader :event

      def initialize(event)
        @event = event
      end

      def matches?(actual)
        actual == event
      end

      def description
        "be #{event.inspect}"
      end
    end

    attr_reader :callable

    def initialize(callable)
      @callable = callable
      super(SubscriberJob)
    end

    def with(event)
      super(EventMatcher.new(event), callable.name)
    end

    def matches?(proc)
      raise ArgumentError, "have_enqueued_async_subscriber_for only supports block expectations" unless Proc === proc
      super
    end
  end
end

RSpec.configure do |config|
  config.include(Module.new do
    def have_enqueued_async_subscriber_for(*args)
      Downstream::HaveEnqueuedAsyncSubscriberFor.new(*args)
    end
  end)
end
