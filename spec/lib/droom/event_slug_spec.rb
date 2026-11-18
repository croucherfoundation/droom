require 'rspec/core'
require 'rspec/expectations'
require 'rspec/mocks'
require 'active_support/all'

module Droom
  module Concerns
  end
end

require_relative '../../../app/models/droom/concerns/slugged'

describe Droom::Concerns::Slugged do
  let(:event_class) { Struct.new(:id, :slug, :uuid) }
  let(:event) { event_class.new(594, "legacy-screening", "existing-uuid") }
  let(:scope) { double }
  let(:conflicts) { double }

  before do
    allow(event_class).to receive(:validates)
    event_class.include(described_class)
    allow(event).to receive_messages(persisted?: true, will_save_change_to_slug?: false)
    allow(event_class).to receive(:where).with(slug: "legacy-screening").and_return(scope)
    allow(scope).to receive_message_chain(:where, :not).with(id: 594).and_return(conflicts)
  end

  it "allocates an unused suffix for a conflicting legacy slug without changing identity" do
    allow(conflicts).to receive(:exists?).and_return(true)
    allow(event_class).to receive(:all).and_return(scope)
    allow(scope).to receive(:find_by).with(slug: "legacy-screening").and_return(double)
    allow(scope).to receive(:find_by).with(slug: "legacy-screening_1").and_return(double)
    allow(scope).to receive(:find_by).with(slug: "legacy-screening_2").and_return(nil)
    allow(event).to receive(:slug?).and_return(false)

    event.resolve_existing_slug_collision

    expect(event.slug).to eq("legacy-screening_2")
    expect(event.id).to eq(594)
    expect(event.uuid).to eq("existing-uuid")
    allow(event_class).to receive(:where).with(slug: event.slug).and_return(scope)
    allow(conflicts).to receive(:exists?).and_return(false)
    event.resolve_existing_slug_collision
    expect(event.slug).to eq("legacy-screening_2")
  end

  it "preserves a nonconflicting existing slug even when other event fields change" do
    allow(conflicts).to receive(:exists?).and_return(false)
    event.resolve_existing_slug_collision
    expect(event.slug).to eq("legacy-screening")
  end

  it "does not silently rewrite an explicitly changed slug" do
    allow(event).to receive(:will_save_change_to_slug?).and_return(true)
    expect(event_class).not_to receive(:where)
    event.resolve_existing_slug_collision
    expect(event.slug).to eq("legacy-screening")
  end

  it "leaves new and blank slugs to the existing slug generator" do
    allow(event).to receive(:persisted?).and_return(false)
    expect(event_class).not_to receive(:where)
    event.resolve_existing_slug_collision
    allow(event).to receive(:persisted?).and_return(true)
    event.slug = nil
    event.resolve_existing_slug_collision
    expect(event.slug).to be_nil
  end
end
