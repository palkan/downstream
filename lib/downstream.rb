# frozen_string_literal: true

require "active_support"
require "active_job"
require "active_model"
require "globalid"
require "after_commit_everywhere"

require "downstream/config"
require "downstream/event"
require "downstream/data_event"
require "downstream/subscriber"
require "downstream/pubsub_adapters/abstract_pubsub"
require "downstream/subscriber_job"

module Downstream
  class << self
    delegate :pubsub, to: :config

    def config
      @config ||= Config.new
    end

    def configure
      yield config
    end

    def subscribe(subscriber = nil, to: nil, async: false, &block)
      subscriber ||= block if block
      raise ArgumentError, "Subsriber must be present" if subscriber.nil?

      construct_identifiers(subscriber, to).map do
        pubsub.subscribe(_1, subscriber, async: async)
      end.then do
        next _1.first if _1.size == 1

        _1
      end
    end

    # temporary subscriptions
    def subscribed(subscriber, to: nil, &block)
      raise ArgumentError, "Subsriber must be present" if subscriber.nil?

      construct_identifiers(subscriber, to).map do
        pubsub.subscribed(_1, subscriber, &block)
      end.then do
        next _1.first if _1.size == 1

        _1
      end
    end

    def publish(event)
      pubsub.publish("#{config.namespace}.#{event.type}", event)
    end

    private

    def construct_identifiers(subscriber, to)
      to ||= infer_events_from_subscriber(subscriber) if subscriber.is_a?(Module)

      if to.nil?
        raise ArgumentError, "Couldn't infer event from subscriber. " \
                              "Please, specify event using `to:` option"
      end

      Array(to).map do
        identifier = if _1.is_a?(Class) && Event >= _1 # rubocop:disable Style/YodaCondition
          _1.identifier
        else
          _1
        end

        "#{config.namespace}.#{identifier}"
      end
    end

    def infer_events_from_subscriber(subscriber)
      if subscriber.is_a?(Class) && Subscriber >= subscriber # rubocop:disable Style/YodaCondition
        return subscriber.event_names
      end

      event_class_name = subscriber.name.split("::").yield_self do |parts|
        # handle explicti top-level name, e.g. ::Some::Event
        parts.shift if parts.first.empty?
        # drop last part—it's a unique subscriber name
        parts.pop

        parts.last.sub!(/^On/, "")

        parts.join("::")
      end

      event_class_name.safe_constantize
    end
  end
end

require "downstream/engine"
