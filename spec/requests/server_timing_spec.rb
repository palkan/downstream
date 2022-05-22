# frozen_string_literal: true

require "spec_helper"

class ServerTimingsController < ActionController::Base
  def index
    Downstream.publish Downstream::TestEvent.new(user_id: 15)
    head :ok
  end
end

Rails.application.routes.draw do
  get "/server-timings-test" => "server_timings#index"
end

describe "Compatibility with Server Timing controller middleware", type: :request do
  it "works" do
    expect { get "/server-timings-test" }
      .to have_published_event(Downstream::TestEvent).with(user_id: 15)
  end
end
