module Droom
  class SubscribeToMailchimpJob < ActiveJob::Base
    # 
    def perform(email, given_name, family_name)
      client = MailchimpMarketing::Client.new
      client.set_config({
        api_key: ENV['MAILCHIMP_API_KEY'],
        server: ENV['MAILCHIMP_SERVER']
      })
      list_id = ENV['MAILCHIMP_LIST_ID']
      member = {
        email_address: email,
        status: "subscribed",
        merge_fields: {
          FNAME: given_name,
          LNAME: family_name
        }
      }
      begin
        client.lists.add_list_member(list_id, member)
        Rails.logger.info("Added #{email} to Mailchimp list")
      rescue MailchimpMarketing::ApiError => e
        Rails.logger.error("Mailchimp API Error: #{e}")
      end

    end
  end
end