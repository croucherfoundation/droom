require File.dirname(__FILE__) + '/../../spec_helper'

describe "Screening EventType seed" do
  it "creates Screening event type with correct slug" do
    et = Droom::EventType.find_or_create_by!(slug: "screening") do |t|
      t.name = "Screening"
    end
    expect(et).to be_persisted
    expect(et.slug).to eq("screening")
    expect(et.name).to eq("Screening")
  end

  it "is findable by slug" do
    Droom::EventType.find_or_create_by!(slug: "screening", name: "Screening")
    expect(Droom::EventType.find_by_slug("screening")).to be_present
  end
end
