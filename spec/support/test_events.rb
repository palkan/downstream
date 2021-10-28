# frozen_string_literal: true

module Downstream
  class TestEvent < Event
    self.identifier = "test_event"

    attributes :user_id, :action_type
  end

  class AnotherTestEvent < TestEvent
  end
end
