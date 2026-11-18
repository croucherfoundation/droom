# Droom

This is a minimal system for secure document and event distribution. It provides a calendar, library and user directory with excellent integration and very little else.

## Status

Brand new. In progress. Little bit volatile, perhaps.

## Installation

In your gemfile:

    gem "droom"

To migrate:

    rake droom:install:migrations
    rake db:migrate

## Sign-in returns

The sign-in page recognises the Warden-resolved session independently of shared-cookie
freshness, refreshes the shared cookie, and returns to `backto` without rotating the
session. Missing/expired sessions use the existing sign-in page; failed attempts retain
the destination. `backto` is already decoded by Rails and must not be decoded again.
Cross-host returns are restricted to HTTP(S) Croucher hosts.

Run the controller regressions without booting the legacy dummy application:

```sh
rspec --options /dev/null test/session_return_spec.rb
```

## Rich Text Sanitizer Foundation

`Droom::SafeHtmlSanitizer` provides a centralized allowlist sanitizer for rich-text fields.

Usage:

```ruby
sanitized = Droom::SafeHtmlSanitizer.sanitize(input_html)
```

Notes:
- Nil-safe input handling (`nil` returns empty string).
- Explicit allowlist tags and attributes.
- Unsafe link protocols (for example `javascript:`) are stripped.
- This is foundation-only; host apps must opt in explicitly per rich-text field.

## Rich Text Opt-In Pattern (D2-AM)

`Droom::RichText::OptIn` defines the reusable model opt-in contract for rich-text attributes without global string sanitization.

```ruby
class ExampleRecord
  include Droom::RichText::OptIn

  rich_text_attributes :description, :notes
end
```

`Droom::RichText::CleanupRunner` provides the cleanup contract for dry-run, batching, and idempotent reprocessing.
    

## Copyright

2012 Spanner Ltd. Released under the same terms as rails.