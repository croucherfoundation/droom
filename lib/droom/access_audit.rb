module Droom
  module AccessAudit
    EVENT_NAME = "access_denied.droom".freeze
    FIELDS = %i[event actor_id ip endpoint_class action outcome].freeze

    def self.record(actor_id:, ip:, endpoint_class:, action:, outcome:)
      payload = {
        event: "object_access_denied",
        actor_id: actor_id,
        ip: ip,
        endpoint_class: endpoint_class,
        action: action,
        outcome: outcome
      }.slice(*FIELDS)

      Rails.logger.warn(payload.to_json)
      ActiveSupport::Notifications.instrument(EVENT_NAME, payload)
      payload
    end
  end
end
