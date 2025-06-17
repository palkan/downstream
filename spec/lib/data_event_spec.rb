# frozen_string_literal: true

require "spec_helper"

describe Downstream::Event, skip: !defined?(Data) do
  let(:event_class) do
    described_class.define(:user_id, :action_type) do
      self.identifier = "test_event"
    end
  end

  let(:event) { event_class.new(user_id: 1, action_type: "test") }

  specify do
    expect(event).to be_frozen
    expect(event.data).to be_a(Data)

    expect(event.user_id).to eq 1
    expect(event.action_type).to eq "test"

    expect(event.data.user_id).to eq 1
    expect(event.data.action_type).to eq "test"

    expect(event.event_id).not_to be_nil
  end

  describe ".identifier" do
    specify "explicit" do
      expect(event_class.identifier).to eq "test_event"
    end

    specify "inferred" do
      stub_const("Downstream::DataTestEvent", Downstream::Event.define(:user_id))
      expect(Downstream::DataTestEvent.identifier).to eq "downstream.data_test"
    end
  end

  describe "#to_h" do
    specify do
      hevent = event.to_h
      expect(hevent).to eq(
        event_id: event.event_id,
        data: {
          user_id: 1,
          action_type: "test"
        },
        type: "test_event"
      )
      expect(hevent).to be_frozen
      expect(hevent[:data]).to be_frozen
    end
  end

  specify "sets event_id if event_id is provided" do
    event = event_class.new(event_id: "123", user_id: 22, action_type: "test")
    expect(event.to_h).to eq(
      event_id: "123",
      data: {
        user_id: 22,
        action_type: "test"
      },
      type: "test_event"
    )
  end

  specify "raises if unknown field is passed" do
    expect { event_class.new(users_ids: [1]) }.to raise_error(
      ArgumentError, /missing keywords: :user_id, :action_type/
    )
  end

  specify "raises argument error if type attribute is defined" do
    expect { described_class.define(:type) }.to raise_error(
      ArgumentError, /type is reserved/
    )
  end

  specify "raises argument error if event_id attribute is defined" do
    expect { described_class.define(:event_id) }.to raise_error(
      ArgumentError, /event_id is reserved/
    )
  end
end
