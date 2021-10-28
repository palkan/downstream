# frozen_string_literal: true

require "spec_helper"

describe "sync #subscribe" do
  let(:event_class) { Downstream::TestEvent }

  it "subscribe with block" do
    events_seen = []

    Downstream.subscribe(to: event_class) do |_name, event|
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

  it "subscribe with callable using identifier" do
    callables = 2.times.map do
      Module.new do
        class << self
          def events
            @events ||= []
          end

          def call(_name, event)
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
end
