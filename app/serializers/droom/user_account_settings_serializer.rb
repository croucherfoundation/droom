class Droom::UserAccountSettingsSerializer < Droom::UserSerializer
  attributes :emergency_contact_eligible, :emergency_contact

  def emergency_contact_eligible
    return @emergency_contact_eligible if defined?(@emergency_contact_eligible)

    @emergency_contact_eligible = unless object.admin?
      person = core_person
      person.present? && person.awards.any? { |award| award.year.present? }
    else
      false
    end
  rescue Faraday::Error, JSON::ParserError, Her::Errors::ParseError => error
    Rails.logger.warn("[Droom::UserAccountSettingsSerializer] Eligibility lookup failed: #{error.message}")
    @emergency_contact_eligible = false
  end

  def emergency_contact
    return unless emergency_contact_eligible

    contact = core_person&.emergency_contact
    return unless contact

    contact = contact.to_h if contact.respond_to?(:to_h)
    contact.stringify_keys.slice("name", "relationship", "address", "phone")
  rescue Faraday::Error, JSON::ParserError, Her::Errors::ParseError => error
    Rails.logger.warn("[Droom::UserAccountSettingsSerializer] Emergency Contact lookup failed: #{error.message}")
    nil
  end

  private

  def core_person
    return @core_person if defined?(@core_person)

    @core_person = Person.for_user(object)
  end
end
