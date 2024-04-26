# frozen_string_literal: true

require "active_support"
require "active_job"
require "active_model"
require "globalid"
require "after_commit_everywhere"

require "downstream/config"
require "downstream/event"
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

      identifier = construct_identifier(subscriber, to)

      pubsub.subscribe(identifier, subscriber, async: async)
    end

    # temporary subscriptions
    def subscribed(subscriber, to: nil, &block)
      raise ArgumentError, "Subsriber must be present" if subscriber.nil?

      identifier = construct_identifier(subscriber, to)

      pubsub.subscribed(identifier, subscriber, &block)
    end

    def publish(event)
      pubsub.publish("#{config.namespace}.#{event.type}", event)
    end

    private

    def construct_identifier(subscriber, to)
      to ||= infer_event_from_subscriber(subscriber) if subscriber.is_a?(Module)

      if to.nil?
        raise ArgumentError, "Couldn't infer event from subscriber. " \
                              "Please, specify event using `to:` option"
      end

      identifier = if to.is_a?(Class) && Event >= to # rubocop:disable Style/YodaCondition
        to.identifier
      else
        to
      end

      "#{config.namespace}.#{identifier}"
    end

    def infer_event_from_subscriber(subscriber)
      event_class_name = subscriber.name.split("::").yield_self do |parts|
        # handle explicti top-level name, e.g. ::Some::Event
        parts.shift if parts.first.empty?
        # drop last part – it's a unique subscriber name
        parts.pop

        parts.last.sub!(/^On/, "")

        parts.join("::")
      end

      event_class_name.safe_constantize
    end
  end
end

require "downstream/engine"
