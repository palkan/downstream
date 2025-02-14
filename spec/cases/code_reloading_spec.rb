# frozen_string_literal: true

require "spec_helper"

describe "Rails #to_prepare" do
  let!(:event_class) { Downstream::TestEvent }

  let!(:callable) do
    Downstream::TestSubscriber =
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

  let(:event) { event_class.new(user_id: 0, action_type: :join) }
  let(:event2) { event_class.new(user_id: 1, action_type: :leave) }

  after do
    Downstream.send(:remove_const, :TestSubscriber) if
      Downstream.const_defined?(:TestSubscriber)
  end

  it "reset subscribers on #to_prepare" do
    ActiveSupport.on_load "downstream-events" do
      Downstream.subscribe(Downstream::TestSubscriber, to: Downstream::TestEvent)
    end

    Downstream.publish(event)

    expect(callable.events.size).to eq 1

    Rails.application.reloader.prepare!

    Downstream.publish(event2)

    expect(callable.events.size).to eq 2
  end
end
