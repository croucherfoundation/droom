require "spec_helper"

describe Droom::SafeHtmlSanitizer do
  describe ".sanitize" do
    it "returns empty string for nil" do
      expect(described_class.sanitize(nil)).to eq("")
    end

    it "keeps allowed formatting tags" do
      html = "<p>Hello <strong>world</strong> <em>team</em></p>"

      expect(described_class.sanitize(html)).to include("<p>")
      expect(described_class.sanitize(html)).to include("<strong>world</strong>")
      expect(described_class.sanitize(html)).to include("<em>team</em>")
    end

    it "removes script tags" do
      html = "<p>ok</p><script>alert(1)</script>"

      expect(described_class.sanitize(html)).to eq("<p>ok</p>alert(1)")
    end

    it "removes event handler attributes" do
      html = '<a href="https://example.com" onclick="alert(1)">link</a>'

      expect(described_class.sanitize(html)).to eq('<a href="https://example.com">link</a>')
    end

    it "strips unsafe href protocols" do
      html = '<a href="javascript:alert(1)">bad</a>'

      expect(described_class.sanitize(html)).to eq('<a>bad</a>')
    end

    it "keeps allowed href protocols" do
      html = '<a href="mailto:test@example.com">mail</a>'

      expect(described_class.sanitize(html)).to eq('<a href="mailto:test@example.com">mail</a>')
    end
  end
end
require "spec_helper"

describe Droom::SafeHtmlSanitizer do
  describe ".sanitize" do
    it "returns empty string for nil" do
      expect(described_class.sanitize(nil)).to eq("")
    end

    it "removes script tags" do
      html = "<p>Hello</p><script>alert('x')</script>"

      expect(described_class.sanitize(html)).to eq("<p>Hello</p>alert('x')")
    end

    it "removes event handler attributes" do
      html = "<p onclick='evil()'>Hello</p>"

      expect(described_class.sanitize(html)).to eq("<p>Hello</p>")
    end

    it "preserves allowed formatting tags" do
      html = "<p><strong>Bold</strong> and <em>italic</em></p><ul><li>One</li></ul>"

      expect(described_class.sanitize(html)).to eq("<p><strong>Bold</strong> and <em>italic</em></p><ul><li>One</li></ul>")
    end

    it "removes javascript links but keeps anchor tag" do
      html = "<a href='javascript:alert(1)'>bad</a>"

      expect(described_class.sanitize(html)).to eq("<a>bad</a>")
    end

    it "keeps safe href protocols" do
      html = "<a href='https://example.com' target='_blank' rel='noopener'>safe</a>"

      expect(described_class.sanitize(html)).to eq("<a href=\"https://example.com\" target=\"_blank\" rel=\"noopener\">safe</a>")
    end
  end
end
