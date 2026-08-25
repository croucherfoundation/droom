require "spec_helper"

describe Droom::RichText::OptIn do
  let(:klass) do
    Class.new do
      include Droom::RichText::OptIn

      attr_accessor :description, :notes, :title

      rich_text_attributes :description, :notes
    end
  end

  it "tracks only opted-in rich-text attributes" do
    expect(klass.rich_text_attribute?(:description)).to be(true)
    expect(klass.rich_text_attribute?(:notes)).to be(true)
    expect(klass.rich_text_attribute?(:title)).to be(false)
  end

  it "sanitizes all opted-in attributes in place" do
    record = klass.new
    record.description = "<p>Hello <script>alert(1)</script> <strong>world</strong></p>"
    record.notes = "<ul><li>safe</li></ul>"

    record.sanitize_rich_text_attributes!

    expect(record.description).to eq("<p>Hello alert(1) <strong>world</strong></p>")
    expect(record.notes).to eq("<ul><li>safe</li></ul>")
  end
end

describe Droom::RichText::CleanupRunner do
  let(:klass) do
    Class.new do
      include Droom::RichText::OptIn

      attr_accessor :id, :description, :notes

      rich_text_attributes :description, :notes

      def self.name
        "ExampleRecord"
      end
    end
  end

  it "returns a dry-run report without mutating changed data" do
    record = klass.new
    record.id = 42
    record.description = "<p><script>alert(1)</script> Hello</p>"

    result = described_class.run(
      model: klass,
      scope: [record],
      attributes: [:description],
      dry_run: true,
      batch_size: 10
    )

    expect(result[:dry_run]).to be(true)
    expect(result[:processed]).to eq(1)
    expect(result[:changed]).to eq(1)
    expect(result[:records].first[:attribute]).to eq("description")
    expect(result[:records].first[:status]).to eq("changed")
    expect(result[:records].first).not_to have_key(:before)
    expect(result[:records].first).not_to have_key(:after)
    expect(record.description).to include("<script>")
  end

  it "reports unchanged attributes without exposing their contents" do
    record = klass.new
    record.id = 43
    record.description = "<p>Already safe</p>"

    result = described_class.run(
      model: klass,
      scope: [record],
      attributes: [:description],
      dry_run: true
    )

    expect(result[:changed]).to eq(0)
    expect(result[:records]).to contain_exactly(
      model: "ExampleRecord",
      record_id: 43,
      attribute: "description",
      status: "unchanged"
    )
  end
end
