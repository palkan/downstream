# frozen_string_literal: true

require "spec_helper"

module TestSubscriptions
  module AsyncCallable
    class << self
      def events
        @events ||= []
      end

      def call(event)
        events << event
      end
    end
  end
end

class TestSubscriber < Downstream::Subscriber
  class << self
    def events
      @events ||= []
    end
  end

  def test_event(event) = self.class.events << event

  alias_method :another_test, :test_event
end

describe "sync #subscribe" do
  let(:event_class) { Downstream::TestEvent }

  it "subscribes with block" do
    events_seen = []

    Downstream.subscribe(to: event_class) do |event|
      events_seen << event
    end

    event = event_class.new(user_id: 0)

    Downstream.publish event

    expect(events_seen.size).to eq 1
    expect(events_seen.last).to eq event

    event2 = event_class.new(user_id: 0, action_type: "leave")
    Downstream.publish event2

    expect(events_seen.size).to eq 2
    expect(events_seen.last).to eq event2
  end

  it "subscribes with callable using identifier" do
    callables = 2.times.map do
      Module.new do
        class << self
          def events
            @events ||= []
          end

          def call(event)
            events << event
          end
        end
      end
    end

    callables.each do |callable|
      Downstream.subscribe(callable, to: "test_event")
    end

    event = event_class.new(user_id: 0)

    Downstream.publish event

    callables.each do |callable|
      expect(callable.events.size).to eq 1
      expect(callable.events.last).to eq event
    end

    event2 = event_class.new(user_id: 42, action_type: "leave")
    Downstream.publish event2

    callables.each do |callable|
      expect(callable.events.size).to eq 2
      expect(callable.events.last).to eq event2
    end
  end

  it "subscribes with a subscriber", skip: !defined?(::Data) do
    Downstream.subscribe(TestSubscriber)

    event = event_class.new(user_id: 0)

    Downstream.publish event

    expect(TestSubscriber.events.size).to eq 1
    expect(TestSubscriber.events.last).to eq event

    another_event_class = ::Downstream::Event.define(:user_id, :action_type) do
      self.identifier = "another_test"
    end

    event2 = another_event_class.new(user_id: 42, action_type: "leave")
    Downstream.publish event2

    expect(TestSubscriber.events.size).to eq 2
    expect(TestSubscriber.events.last).to eq event2
  end

  it "temporary subscribes" do
    event = event_class.new(user_id: 0)

    events_seen = []

    subscriber = ->(event) do
      events_seen << event
    end

    Downstream.subscribed(subscriber, to: event_class) do
      Downstream.publish event
    end

    expect(events_seen.size).to eq 1
    expect(events_seen.last).to eq event

    events_seen = []

    Downstream.publish event

    expect(events_seen.size).to eq 0
  end

  it "subscribes async" do
    Downstream.subscribe(TestSubscriptions::AsyncCallable, to: event_class, async: true)

    event = event_class.new(user_id: 0)

    expect { Downstream.publish(event) }.to have_enqueued_job(Downstream::SubscriberJob)
      .with(event, "TestSubscriptions::AsyncCallable")
    expect(TestSubscriptions::AsyncCallable.events).to be_empty
  end
end
