require "logger"

module Droom
  module RichText
    class CleanupRunner
      DEFAULT_BATCH_SIZE = 100

      attr_reader :model, :scope, :attributes, :batch_size, :dry_run, :limit, :logger

      def self.run(model:, scope: nil, attributes: nil, batch_size: DEFAULT_BATCH_SIZE, dry_run: true, limit: nil, logger: nil)
        new(
          model: model,
          scope: scope,
          attributes: attributes,
          batch_size: batch_size,
          dry_run: dry_run,
          limit: limit,
          logger: logger
        ).call
      end

      def initialize(model:, scope: nil, attributes: nil, batch_size: DEFAULT_BATCH_SIZE, dry_run: true, limit: nil, logger: nil)
        @model = model
        @scope = scope || (model.respond_to?(:all) ? model.all : model)
        @attributes = normalize_attributes(attributes)
        @batch_size = batch_size.to_i.positive? ? batch_size.to_i : DEFAULT_BATCH_SIZE
        @dry_run = !!dry_run
        @limit = limit
        @logger = logger || Logger.new($stdout)
      end

      def call
        report = {
          model: model.name,
          dry_run: dry_run,
          processed: 0,
          changed: 0,
          skipped: 0,
          records: []
        }

        each_record do |record|
          report[:processed] += 1

          attribute_changes = []
          attributes.each do |attribute_name|
            next unless record.respond_to?(attribute_name)

            original = record.public_send(attribute_name)
            sanitized = Droom::SafeHtmlSanitizer.sanitize(original)

            if original.to_s == sanitized
              report[:skipped] += 1
              next
            end

            attribute_changes << {
              model: record.class.name,
              record_id: record.respond_to?(:id) ? record.id : nil,
              attribute: attribute_name.to_s,
              changed: true,
              before: summarize(original),
              after: summarize(sanitized)
            }

            next if dry_run

            record.public_send("#{attribute_name}=", sanitized)
          end

          next if attribute_changes.empty?

          report[:changed] += attribute_changes.length
          report[:records].concat(attribute_changes)

          record.save! unless dry_run
        end

        report
      end

      private

      def normalize_attributes(attributes)
        return Array(model.respond_to?(:rich_text_attribute_names) ? model.rich_text_attribute_names : []) if attributes.nil?

        Array(attributes).map(&:to_sym)
      end

      def each_record
        records = if scope.respond_to?(:find_each)
                    scope.limit(limit).find_each(batch_size: batch_size)
                  elsif scope.respond_to?(:each)
                    scope.each
                  else
                    [scope]
                  end

        records.each do |record|
          yield record
        end
      end

      def summarize(value)
        return "" if value.nil?

        value.to_s.truncate(200)
      end
    end
  end
end
