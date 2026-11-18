# Exact identity lookup. A failed service request is not evidence of no person.
class CoreIdentityLookup
  def self.for_user(user)
    Person.get_raw("/api/people/user/#{ERB::Util.url_encode(user.uid.to_s)}") do |data, response|
      return nil if response.status == 404
      raise 'Core identity lookup failed' unless response.status == 200
      person = Person.new_from_parsed_data(data)
      raise 'Core returned an invalid identity' if person.uid.blank?
      person
    end
  end
end
