# frozen_string_literal: true

module Downstream
  module Stateless
    class Subscriber
      include AfterCommitEverywhere

      attr_reader :callable, :async

      def initialize(callable, async: false)
        @callable = callable
        @async = async
      end

      def async?
        !!async
      end

      def call(_name, event)
        if async?
          if callable.is_a?(Proc) || callable.name.nil?
            raise ArgumentError, "Anonymous subscribers (blocks/procs/lambdas or anonymous modules) cannot be asynchronous"
          end

          raise ArgumentError, "Async subscriber must be a module/class, not instance" unless callable.is_a?(Module)

          after_commit do
            SubscriberJob.then do |job|
              if (queue_name = async_queue_name)
                job.set(queue: queue_name)
              else
                job
              end
            end.perform_later(event, callable.name)
          end
        else
          callable.call(event)
        end
      end

      def subscribe(identifier)
        @notification_subscriber = ActiveSupport::Notifications.subscribe(
          identifier,
          self
        )
      end

      def unsubscribe
        ActiveSupport::Notifications.unsubscribe(notification_subscriber)
      end

      private

      attr_reader :notification_subscriber

      def async_queue_name
        return @async_queue_name if defined?(@async_queue_name)

        name = async[:queue] if async.is_a?(Hash)
        name ||= Downstream.config.async_queue

        @async_queue_name = name
      end
    end
  end
end
