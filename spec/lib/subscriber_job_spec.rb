# frozen_string_literal: true

require "spec_helper"

module TestSubscriberJob
  module Subscriber
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

describe Downstream::SubscriberJob do
  let(:event_class) { Downstream::TestEvent }
  let(:event) { event_class.new(user_id: 1) }
  let(:callable) { "TestSubscriberJob::Subscriber" }

  subject { described_class.perform_now(event, callable) }

  it "handles an event" do
    subject
    expect(TestSubscriberJob::Subscriber.events.size).to eq 1
    expect(TestSubscriberJob::Subscriber.events.first).to eq event
  end
end
