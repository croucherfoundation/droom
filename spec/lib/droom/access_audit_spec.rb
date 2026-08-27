require File.dirname(__FILE__) + '/../../spec_helper'
require 'json'

describe Droom::AccessAudit do
  it 'emits only the approved non-sensitive audit fields' do
    logged_payload = nil
    subscribed_payload = nil

    allow(Rails.logger).to receive(:warn) { |message| logged_payload = JSON.parse(message) }
    allow(ActiveSupport::Notifications).to receive(:instrument) do |_event, payload|
      subscribed_payload = payload
    end

    payload = described_class.record(
      actor_id: 14531,
      ip: '203.0.113.10',
      endpoint_class: 'Droom::FoldersController',
      action: 'show',
      outcome: 'not_found'
    )

    expected_fields = %w[event actor_id ip endpoint_class action outcome]
    expect(payload.keys.map(&:to_s)).to match_array(expected_fields)
    expect(logged_payload.keys).to match_array(expected_fields)
    expect(subscribed_payload).to eq(payload)
    expect(logged_payload.to_json).not_to match(/@|amazonaws|X-Amz-Signature/i)
  end
end
