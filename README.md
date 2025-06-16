[![Gem Version](https://badge.fury.io/rb/downstream.svg)](https://badge.fury.io/rb/downstream)
[![Build Status](https://github.com/bibendi/downstream/workflows/Ruby/badge.svg?branch=master)](https://github.com/bibendi/downstream/actions?query=branch%3Amaster)

# Downstream

This gem provides a straightforward way to implement communication between Rails Engines using the Publish-Subscribe pattern. The gem allows decreasing the coupling of engines with events. An event is a recorded object in the system that reflects an action that the engine performs, and the params that lead to its creation.

The gem inspired by [`active_event_store`](https://github.com/palkan/active_event_store), and initially based on its codebase. Having said that, it does not store in a database all happened events which ensures simplicity and performance.

<a href="https://evilmartians.com/?utm_source=bibendi-downstream">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

## Installation

Add this line to your application's Gemfile:

```ruby
gem "downstream", "~> 1.0"
```

## Usage

Downstream provides a way more handy interface to build reactive apps. Each event has a strict schema described by a separate class. The gem has convenient tooling to write tests.

Downstream supports various adapters for event handling. It can be configured in a Rails initializer `config/initializers/downstream.rb`:

```ruby
Downstream.configure do |config|
  config.pubsub = :stateless # it's a default adapter
  config.async_queue = :high_priority # nil by default
end
```

For now, it's implemented only one adapter. The `stateless` adapter is based on `ActiveSupport::Notifications`, and it doesn't store history events anywhere. All event invocations are synchronous. Adding asynchronous subscribers are on my road map.

### Describe events

Events are represented by _event classes_, which describe events payloads and identifiers:

```ruby
class ProfileCreated < Downstream::Event
  # (optional)
  # Event identifier is used for streaming events to subscribers.
  # By default, identifier is equal to underscored class name.
  # You don't need to specify identifier manually, only for backward compatibility when
  # class name is changed.
  self.identifier = "profile_created"

  # Add attributes accessors
  attributes :user
end
```

Each event has predefined (_reserved_) fields:
- `event_id` – unique event id
- `type` – event type (=identifier)

**NOTE:** events should be in the past tense and describe what happened (e.g. "ProfileCreated", "EventPublished", etc.).

Events are stored in `app/events` folder.

You can also define events using the Data-interface:

```ruby
ProfileCreated = Downstream::Event.define(:user)

# or with an explicit identifier
ProfileCreated = Downstream::Event.define(:user) do
  self.identifier = "user.profile_created"
end
```

Date-events provide the same interface as regular events but use Data classes for keeping event payloads (`event.data`) and are frozen (as well as their derivatives, such as `event.to_h`).

> [!NOTE]
> Data-events are only available in Ruby 3.2+.

### Publish events

To publish an event you must first create an instance of the event class and call `Downstream.publish` method:

```ruby
event = ProfileCompleted.new(user: user)

# then publish the event
Downstream.publish(event)
```

That's it! Your event has been stored and propagated.

### Subscribe to events

To subscribe a handler to an event you must use `Downstream.subscribe` method.

You should do this in your app or engine initializer:

```ruby
# some/engine.rb

initializer "my_engine.subscribe_to_events" do
  # To make sure event store is initialized use load hook
  # `store` == `Downstream`
  ActiveSupport.on_load "downstream-events" do |store|
    store.subscribe MyEventHandler, to: ProfileCreated

    # anonymous handler (could only be synchronous)
    store.subscribe(to: ProfileCreated) do |event|
      # do something
    end

    # you can omit event if your subscriber follows the convention
    # for example, the following subscriber would subscribe to
    # ProfileCreated event
    store.subscribe OnProfileCreated::DoThat
  end
end
```

**NOTE:** event handler **must** be a callable object.

Although subscriber could be any callable Ruby object, that have specific input format (event); thus we suggest putting subscribers under `app/subscribers/on_<event_type>/<subscriber.rb>`, e.g. `app/subscribers/on_profile_created/create_chat_user.rb`).

Sometimes, you may be interested in using temporary subscriptions. For that, you can use this:

```ruby
subscriber = ->(event) { my_event_handler(event) }
Downstream.subscribed(subscriber, to: ProfileCreated) do
  some_invocation
end
```

If you want to handle events in a background job, you can pass the `async: true` option:

```ruby
store.subscribe OnProfileCreated::DoThat, async: true
```

By default, a job will be enqueued into `async_queue` name from the Downstream config. You can define your own queue name for a specific subscriber:

```ruby
store.subscribe OnProfileCreated::DoThat, async: {queue: :low_priority}
```

**NOTE:** all subscribers are synchronous by default

## Testing

You can test subscribers as normal Ruby objects.

First, load testing helpers in the `spec_helper.rb`:

```ruby
require "downstream/rspec"
```

To test that a given subscriber exists, you can do the following:

```ruby
it "is subscribed to some event" do
  allow(MySubscriberService).to receive(:call)

  event = MyEvent.new(some: "data")

  Downstream.publish event

  expect(MySubscriberService).to have_received(:call).with(event)
end

# for asynchronous subscriptions
it "is subscribed to some event" do
  event = MyEvent.new(some: "data")
  expect { Downstream.publish event }
    .to have_enqueued_async_subscriber_for(MySubscriberService)
    .with(event)
end
```

To test publishing use `have_published_event` matcher:

```ruby
expect { subject }.to have_published_event(ProfileCreated).with(user: user)
```

**NOTE:** `have_published_event` only supports block expectations.

**NOTE 2** `with` modifier works like `have_attributes` matcher (not `contain_exactly`);
