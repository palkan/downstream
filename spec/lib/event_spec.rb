# frozen_string_literal: true

require "spec_helper"

describe Downstream::Event do
  let(:event_class) { Downstream::TestEvent }

  let(:event) { event_class.new(user_id: 1, action_type: "test") }

  specify do
    expect(event.user_id).to eq 1
    expect(event.action_type).to eq "test"
    expect(event.event_id).not_to be_nil
  end

  describe ".identifier" do
    specify "explicit" do
      expect(Downstream::TestEvent.identifier).to eq "test_event"
    end

    specify "inferred" do
      expect(Downstream::AnotherTestEvent.identifier).to eq "downstream.another_test_event"
    end
  end

  describe "#to_h" do
    specify do
      expect(event.to_h).to eq(
        event_id: event.event_id,
        data: {
          user_id: 1,
          action_type: "test"
        },
        type: "test_event"
      )
    end
  end

  specify "sets event_id if event_id is provided" do
    event = event_class.new(event_id: "123", user_id: 22)
    expect(event.to_h).to eq(
      event_id: "123",
      data: {
        user_id: 22
      },
      type: "test_event"
    )
  end

  specify "raises if unknown field is passed" do
    expect { event_class.new(users_ids: [1]) }.to raise_error(
      ArgumentError, /Unknown event attributes: users_ids/
    )
  end

  specify "raises argument error if type attribute is defined" do
    expect { Class.new(described_class) { attributes :type } }.to raise_error(
      ArgumentError, /type is reserved/
    )
  end

  specify "raises argument error if event_id attribute is defined" do
    expect { Class.new(described_class) { attributes :event_id } }.to raise_error(
      ArgumentError, /event_id is reserved/
    )
  end
end
