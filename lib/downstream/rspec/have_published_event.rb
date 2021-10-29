# frozen_string_literal: true

module Downstream
  class HavePublishedEvent < RSpec::Matchers::BuiltIn::BaseMatcher
    attr_reader :event_class, :attributes

    def initialize(event_class)
      @event_class = event_class
      set_expected_number(:exactly, 1)
    end

    def with(attributes)
      @attributes = attributes
      self
    end

    def exactly(count)
      set_expected_number(:exactly, count)
      self
    end

    def at_least(count)
      set_expected_number(:at_least, count)
      self
    end

    def at_most(count)
      set_expected_number(:at_most, count)
      self
    end

    def times
      self
    end

    def once
      exactly(:once)
    end

    def twice
      exactly(:twice)
    end

    def thrice
      exactly(:thrice)
    end

    def supports_block_expectations?
      true
    end

    def matches?(block)
      raise ArgumentError, "have_published_event only supports block expectations" unless block.is_a?(Proc)

      @matching_events = []

      subscriber = ->(event) do
        if attributes.nil? || attributes_match?(event)
          @matching_events << event
        end
      end

      Downstream.subscribed(subscriber, to: event_class) do
        block.call
      end

      @matching_count = @matching_events.size

      case @expectation_type
      when :exactly then @expected_number == @matching_count
      when :at_most then @expected_number >= @matching_count
      when :at_least then @expected_number <= @matching_count
      end
    end

    def failure_message
      (+"expected to publish #{event_class.identifier} event").tap do |msg|
        msg << " #{message_expectation_modifier}, but haven't published"
      end
    end

    def failure_message_when_negated
      "expected not to publish #{event_class.identifier} event"
    end

    private

    def attributes_match?(event)
      RSpec::Matchers::BuiltIn::HaveAttributes.new(attributes).matches?(event)
    end

    def set_expected_number(relativity, count)
      @expectation_type = relativity
      @expected_number =
        case count
        when :once then 1
        when :twice then 2
        when :thrice then 3
        else Integer(count)
        end
    end

    def message_expectation_modifier
      number_modifier = @expected_number == 1 ? "once" : "#{@expected_number} times"
      case @expectation_type
      when :exactly then "exactly #{number_modifier}"
      when :at_most then "at most #{number_modifier}"
      when :at_least then "at least #{number_modifier}"
      end
    end
  end
end

RSpec.configure do |config|
  config.include(Module.new do
    def have_published_event(*args)
      Downstream::HavePublishedEvent.new(*args)
    end
  end)
end
