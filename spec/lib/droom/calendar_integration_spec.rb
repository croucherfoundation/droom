require 'rspec/core'
require 'rspec/expectations'
require 'rspec/mocks'
require 'active_support/all'
require 'cancan'
require 'icalendar'
require 'action_view'
require 'haml'
require 'active_model_serializers'
require_relative '../../../lib/droom/calendar_description'
require_relative '../../../lib/droom/calendar_export'
require_relative '../../../lib/droom/screening_calendar_access'
require_relative '../../../app/serializers/droom/calendar_serializer'
require_relative '../../../app/serializers/droom/event_serializer'

describe Droom::CalendarExport do
  let(:record) do
    Class.new do
      include Droom::CalendarDescription
      include ActionView::Helpers::SanitizeHelper
      include Droom::CalendarExport
    end.new
  end
  let(:deadline) { Time.find_zone!("Asia/Hong_Kong").parse("2026-12-31 00:00") }

  before do
    allow(record).to receive_messages(
      uuid: "stable-uuid", name: "Technology screening deadline",
      description?: true, plain_description: "View assigned applications",
      all_day?: true, start?: true, start: deadline, start_date: deadline.to_date,
      finish?: true, finish: deadline + 1.day, finish_date: (deadline + 1.day).to_date,
      end_date: deadline.to_date, updated_at: deadline - 1.day, calendar_sequence: 0,
      url?: true, url_with_protocol: "https://apps.example.test/screening", venue: nil,
      invitations: double(accepted: [])
    )
  end

  it "exports exactly one date-only day, including across a year boundary" do
    ics = record.icalendar_event.to_ical
    expect(ics).to include("DTSTART;VALUE=DATE:20261231", "DTEND;VALUE=DATE:20270101")
    expect(ics).to include("UID:stable-uuid", "https://apps.example.test/screening", "DTSTAMP:20261229T160000Z")
    expect(ics).not_to include("DTSTART:20261231T")
  end

  it "keeps the UID but advances SEQUENCE even when two edits have the same timestamp" do
    first = record.icalendar_event
    allow(record).to receive(:calendar_sequence).and_return(1)
    updated = record.icalendar_event
    expect(updated.uid).to eq(first.uid)
    expect(updated.sequence.to_i).to be > first.sequence.to_i
    expect(updated.last_modified).to eq(first.last_modified)
  end

  it "keeps interviews timed with their venue and duration" do
    allow(record).to receive_messages(all_day?: false, venue: double(name: "Interview room"),
      start: deadline.change(hour: 9), finish: deadline.change(hour: 11))
    ics = record.icalendar_event.to_ical
    expect(ics).to include("DTSTART", "DTEND", "LOCATION:Interview room")
    expect(ics).not_to include("VALUE=DATE:")
    expect(record.icalendar_event.dtend.to_time - record.icalendar_event.dtstart.to_time).to eq(7_200)
  end

  it "uses each subscription owner's description without changing the shared UID" do
    allow(record).to receive_messages(event_type: double(slug: "screening"), description: "<p>Panel total</p>")
    allow(record).to receive(:plain_description).and_call_original
    first = double(invited_to?: true, screening_calendar_descriptions: { "stable-uuid" => "<p>Screen 3 applications &amp; submit scores.</p>" })
    second = double(invited_to?: true, screening_calendar_descriptions: { "stable-uuid" => "<p>Screen 7 applications.</p>" })

    expect(record.description_for(first)).to include("Screen 3")
    expect(record.description_for(second)).to include("Screen 7")
    first_export = record.icalendar_event(user: first)
    second_export = record.icalendar_event(user: second)
    expect(first_export.description.to_s).to eq("Screen 3 applications & submit scores.")
    expect(second_export.description.to_s).to eq("Screen 7 applications.")
    expect(first_export.uid).to eq(second_export.uid)
    expect(record.description).to eq("<p>Panel total</p>")
  end

  it "does not silently substitute the panel total when personalization is missing" do
    allow(record).to receive_messages(event_type: double(slug: "screening"), description: "Panel total")
    judge = double(invited_to?: true, screening_calendar_descriptions: {})
    expect { record.description_for(judge) }.to raise_error(KeyError)
  end

  it "exports a personalized description even before an empty legacy shared description is refreshed" do
    allow(record).to receive_messages(event_type: double(slug: "screening"), description: nil, description?: false)
    allow(record).to receive(:plain_description).and_call_original
    judge = double(invited_to?: true, screening_calendar_descriptions: { "stable-uuid" => "<p>Screen 3 applications.</p>" })
    expect(record.icalendar_event(user: judge).description.to_s).to eq("Screen 3 applications.")
  end

  it "keeps the stored description for unassigned staff and interview events" do
    allow(record).to receive_messages(event_type: double(slug: "screening"), description: "Panel total")
    staff = double(invited_to?: false)
    expect(record.description_for(staff)).to eq("Panel total")
    allow(record).to receive_messages(event_type: double(slug: "award_interviews"), description: "Interview timetable")
    expect(record.description_for(double)).to eq("Interview timetable")
  end

  it "renders the actual event popup with the viewer's count rather than the stored panel total" do
    allow(record).to receive_messages(event_type: double(slug: "screening"), description: "Panel total")
    judge = double(invited_to?: true, screening_calendar_descriptions: { "stable-uuid" => "<p>Screen 3 applications.</p>" })
    view = Class.new { include ActionView::Helpers }.new
    allow(view).to receive_messages(current_user: judge, event_url: "/events/838", t: "Download calendar")
    template = Haml::Template.new(File.expand_path('../../../app/views/droom/events/_popup_event.html.haml', __dir__))
    html = template.render(view, event: record)
    expect(html).to include("Screen 3 applications.")
    expect(html).not_to include("Panel total")
  end

  it "uses the authenticated serialization scope for JSON event descriptions" do
    judge = double
    expect(record).to receive(:description_for).with(judge).and_return("Screen 3 applications.")
    expect(Droom::EventSerializer.new(record, scope: judge).description).to eq("Screen 3 applications.")
  end
end

describe "Personalized calendar controller integration" do
  before do
    base = Class.new
    [:respond_to, :prepend_before_action, :before_action, :load_and_authorize_resource,
      :skip_before_action, :load_resource].each do |method|
      allow(base).to receive(method)
    end
    stub_const("Droom::DroomController", base)
    stub_const("Droom::Concerns", Module.new)
    stub_const("Droom::Concerns::ScanAttachedFile", Module.new)
    stub_const("Droom::EventsController", Class.new(base))
    stub_const("Droom::Api", Module.new)
    stub_const("Droom::Api::ApiController", base)
    load File.expand_path('../../../app/controllers/droom/events_controller.rb', __dir__)
    load File.expand_path('../../../app/controllers/droom/api/events_controller.rb', __dir__)
  end

  it "passes the subscription owner to the exporter" do
    owner = double
    event = double
    ical = Icalendar::Event.new
    ical.uid = "shared-uuid"
    ical.description = "Screen 3 applications."
    expect(event).to receive(:icalendar_event).with(user: owner).and_return(ical)
    controller = Droom::EventsController.new
    controller.instance_variable_set(:@events, [event])
    allow(controller).to receive(:current_user).and_return(owner)
    expect(controller).to receive(:render) do |options|
      expect(options[:content_type]).to eq("text/calendar")
      expect(options[:plain]).to include("UID:shared-uuid", "DESCRIPTION:Screen 3 applications.")
    end
    controller.subscribe
  end

  it "passes the viewer to single-event ICS downloads too" do
    owner = double
    event = double
    ical = Icalendar::Event.new
    ical.uid = "shared-uuid"
    expect(event).to receive(:icalendar_event).with(user: owner).and_return(ical)
    controller = Droom::EventsController.new
    controller.instance_variable_set(:@event, event)
    allow(controller).to receive(:current_user).and_return(owner)
    format = double(html: nil, js: nil, zip: nil)
    allow(controller).to receive(:respond_with).with(event).and_yield(format)
    expect(format).to receive(:ics).and_yield
    expect(controller).to receive(:render).with(hash_including(content_type: "text/calendar"))
    controller.show
  end

  it "retains assigned screening and interview events in a scholar's authorized feed" do
    ability = double
    owner = double(event_ids: [838, 839])
    authorized = double
    other_events = double
    assigned_events = double
    result = double
    types = double
    stub_const("Droom::Event", Class.new)
    stub_const("Droom::EventType", Class.new)
    allow(Droom::Event).to receive(:accessible_by).with(ability).and_return(authorized)
    allow(Droom::EventType).to receive(:find_by_slug).with("other_events").and_return(double(id: 1))
    expect(Droom::EventType).to receive(:where).with(slug: ["screening", "award_interviews"]).and_return(types)
    allow(types).to receive(:select).with(:id).and_return(types)
    expect(authorized).to receive(:where).with(event_type_id: 1).and_return(other_events)
    expect(authorized).to receive(:where).with(event_type_id: types, id: [838, 839]).and_return(assigned_events)
    expect(other_events).to receive(:or).with(assigned_events).and_return(result)
    allow(Droom).to receive(:config).and_return(double(separate_calendars?: false))
    controller = Droom::EventsController.new
    allow(controller).to receive_messages(current_user: owner, current_ability: ability, scholar?: true)

    expect(controller.send(:get_my_events)).to eq(result)
  end

  it "advances the screening version on assignment-only syncs with unchanged shared attributes" do
    event = double(event_type: double(slug: "screening"), previous_changes: {})
    allow(event).to receive(:update).with({}).and_return(true)
    expect(event).to receive(:touch)
    controller = Droom::Api::EventsController.new
    controller.instance_variable_set(:@event, event)
    allow(controller).to receive(:event_params).and_return({})
    expect(controller).to receive(:render_api_success).with(resource: event)
    controller.update
  end

  it "returns validation errors as 422 without touching or reporting a successful update" do
    errors = double
    event = double(errors: errors)
    expect(event).to receive(:update).with({}).and_return(false)
    expect(event).not_to receive(:touch)
    controller = Droom::Api::EventsController.new
    controller.instance_variable_set(:@event, event)
    allow(controller).to receive(:event_params).and_return({})
    expect(controller).not_to receive(:render_api_success)
    expect(controller).to receive(:render_api_error).with(errors: errors, status: :unprocessable_entity)
    controller.update
  end
end

describe Droom::CalendarSerializer do
  it "preserves the single-day UI contract and links deadlines directly to assigned applications" do
    date = Time.find_zone!("Asia/Hong_Kong").parse("2026-12-31 00:00")
    record = double(id: 838, name: "Deadline", start: date, end_date: date.to_date,
      start_time: date, all_day: true, event_type: double(slug: "screening"),
      url?: true, url_with_protocol: "https://apps.example.test/screening")
    allow(record).to receive(:read_attribute_for_serialization) { |attribute| record.public_send(attribute) }
    serializer = described_class.new(record)
    expect(serializer.attributes).to include(
      all_day: true, start: "31 December 2026, 00:00", end: "31 December 2026, 00:00",
      full_url: "https://apps.example.test/screening"
    )
  end
end

describe Droom::ScreeningCalendarAccess do
  let(:event_class) { Struct.new(:id, :event_type_id) }
  let(:event) { event_class.new(838, 7) }
  let(:ability) { Class.new { include CanCan::Ability }.new }
  let(:user) do
    double(persisted?: true, data_room_user?: true, admin?: false, staff?: false,
      permitted?: true, event_ids: [], invited_to?: false)
  end

  before do
    stub_const("Droom::Event", event_class)
    stub_const("Droom::EventType", Class.new)
    allow(Droom::EventType).to receive_message_chain(:where, :pluck).and_return([7])
    ability.can :manage, Droom::Event
  end

  it "denies an unassigned governor despite broad calendar permission" do
    described_class.apply(ability, user)
    expect(ability.can?(:show, event)).to be false
    expect(ability.can?(:update, event)).to be false
    expect(described_class.visible_to?(event, user)).to be false
    expect(ability.can?(:show, event_class.new(1, 8))).to be true
  end

  it "allows assigned external judges to read and subscribe but not edit" do
    allow(user).to receive_messages(event_ids: [838], invited_to?: true, permitted?: false)
    described_class.apply(ability, user)
    expect(ability.can?(:show, event)).to be true
    expect(ability.can?(:subscribe, event)).to be true
    expect(ability.can?(:update, event)).to be false
    expect(described_class.visible_to?(event, user)).to be true
  end

  it "revokes event access when the invitation is removed" do
    described_class.apply(ability, user)
    expect(ability.can?(:show, event)).to be false
  end

  it "allows authorized office staff and administrators" do
    allow(user).to receive(:staff?).and_return(true)
    described_class.apply(ability, user)
    expect(ability.can?(:show, event)).to be true
    expect(ability.can?(:update, event)).to be false
    expect(described_class.visible_to?(event, user)).to be true
    allow(user).to receive_messages(staff?: false, admin?: true)
    expect(described_class.visible_to?(event, user)).to be true
  end

  it "does not grant office staff access without calendar permission" do
    allow(user).to receive_messages(staff?: true, permitted?: false)
    described_class.apply(ability, user)
    expect(ability.can?(:show, event)).to be false
  end
end
