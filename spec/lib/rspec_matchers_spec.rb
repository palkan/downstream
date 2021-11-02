# frozen_string_literal: true

require "spec_helper"

describe "RSpec matchers" do
  let(:event_class) { Downstream::TestEvent }
  let(:event) { event_class.new(user_id: 25, action_type: "birth") }
  let(:event2) { event_class.new(user_id: 1, action_type: "death") }

  describe "#have_published_event" do
    context "success" do
      specify "with only event class" do
        expect { Downstream.publish event }
          .to have_published_event(event_class)
      end

      specify "with event class and one attribute" do
        expect { Downstream.publish event }
          .to have_published_event(event_class).with(user_id: 25)
      end

      specify "with event class and many attributes" do
        expect { Downstream.publish event }
          .to have_published_event(event_class).with(user_id: 25, action_type: "birth")
      end

      specify "with times modifier" do
        expect do
          Downstream.publish event
          Downstream.publish event2
        end.to have_published_event(event_class).twice
      end
    end

    context "failure" do
      specify "no events published" do
        expect do
          expect { true }
            .to have_published_event(event_class)
        end.to raise_error(/to publish test_event.+exactly once, but haven't published/)
      end

      specify "class doesn't match" do
        expect do
          expect { Downstream.publish event }
            .to have_published_event(Downstream::AnotherTestEvent)
        end.to raise_error(/to publish downstream.another_test_event.+exactly once, but/)
      end

      specify "attributes don't match" do
        expect do
          expect { Downstream.publish event }
            .to have_published_event(event_class).with(user_id: 25, action_type: "death")
        end.to raise_error(/to publish test_event.+exactly once, but/)
      end

      specify "not_to published" do
        expect do
          expect { Downstream.publish event }
            .not_to have_published_event(event_class)
        end.to raise_error(/not to publish test_event/)
      end
    end
  end

  describe "#have_async_enqueued_subscriber_for" do
    before do
      Downstream::TestSubscriber =
        Module.new do
          class << self
            def call(_event)
            end
          end
        end
    end

    after do
      Downstream.send(:remove_const, :TestSubscriber) if
        Downstream.const_defined?(:TestSubscriber)
    end

    let(:subscriber_class) { Downstream::TestSubscriber }

    specify "success" do
      subscriber = Downstream.subscribe(subscriber_class, to: event_class, async: true)

      expect { Downstream.publish event }
        .to have_enqueued_async_subscriber_for(subscriber_class)

      subscriber.unsubscribe
    end

    specify "success with event" do
      subscriber = Downstream.subscribe(subscriber_class, to: event_class, async: true)

      expect { Downstream.publish event }
        .to have_enqueued_async_subscriber_for(subscriber_class).with(event)

      subscriber.unsubscribe
    end

    specify "failure when no async subscribers" do
      subscriber = Downstream.subscribe(subscriber_class, to: event_class)

      expect do
        expect { Downstream.publish event }
          .not_to have_enqueued_async_subscriber_for(subscriber_class)
      end

      subscriber.unsubscribe
    end

    specify "failure when wrong event type" do
      subscriber = Downstream.subscribe(subscriber_class, to: event_class)

      expect do
        expect { Downstream.publish event }
          .to have_enqueued_async_subscriber_for(subscriber_class).with(event2)
      end.to raise_error(/expected to enqueue/)

      subscriber.unsubscribe
    end
  end
end
