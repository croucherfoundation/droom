require 'signed_json'
require "active_support/core_ext/hash/slice"

# NB. there is vital callback glue in droom/config/initializers/devise.rb
#
module Droom
  class AuthCookie

    def initialize(cookies)
      @cookies = cookies
    end

    # Sets the cookie, referencing the given resource.id (e.g. User)
    def set(resource, opts={})
      cookie = cookie_options.merge(opts).merge(same_site: :lax, path: "/", value: encoded_value(resource))
      @cookies[cookie_name] = cookie
    end

    # Unsets the cookie via the HTTP response.
    def unset
      options = cookie_options.merge(same_site: :lax, path: "/")
      @cookies.delete cookie_name, options
    end

    def token
      values[0]
    end

    # The Time at which the cookie was created.
    def created_at
      DateTime.parse(values[1]) if valid?
    end

    # Whether the cookie appears valid.
    def valid?
      present?
    end

    def present?
      @cookies[cookie_name].present? && values.all?
    end

    def fresh?
      set_since?(Time.now - cookie_lifespan.minutes)
    end

    # Whether the cookie was set since the given Time
    def set_since?(time)
      created_at && created_at >= time
    end

    def store?
      false
    end

  private
    
    # cookie value format is [uid, auth_token, time]
    #
    def values
      begin
        @values = signer.decode(@cookies[cookie_name])
      rescue SignedJson::Error
        [nil, nil]
      end
    end

    def cookie_name
      ENV['DROOM_AUTH_COOKIE'] || Settings.auth.cookie_name
    end

    def cookie_domain
      ENV['DROOM_AUTH_COOKIE_DOMAIN'] || Settings.auth.cookie_domain
    end

    def auth_secret
      ENV['DROOM_AUTH_SECRET'] || Settings.auth.secret
    end

    def cookie_lifespan
      (ENV['DROOM_AUTH_COOKIE_EXPIRY'] || Settings.auth.cookie_period).to_i
    end

    def encoded_value(resource)
      signer.encode([resource.ensure_unique_session_id!, Time.now])
    end

    def cookie_options
      @session_options ||= Rails.configuration.session_options
      @session_options[:domain] = cookie_domain
      # @session_options[:httponly] = true
      # @session_options[:secure] = true
      @session_options.slice(:path, :domain, :secure, :httponly)
    end

    def signer
      @signer ||= SignedJson::Signer.new(auth_secret)
    end

  end
end