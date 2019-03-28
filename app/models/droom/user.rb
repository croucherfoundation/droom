require 'digest'

module Droom
  class User < ActiveRecord::Base
    validates :family_name, :presence => true
    validates :given_name, :presence => true
    validates :uid, :uniqueness => true, :presence => true

    has_many :preferences, :foreign_key => "created_by_id"
    accepts_nested_attributes_for :preferences, :allow_destroy => true

    ## Authentication
    #
    devise :database_authenticatable,
           :cookie_authenticatable,
           :recoverable,
           :trackable,
           :confirmable,
           :rememberable,
           :session_limitable,
           :lockable,
           reconfirmable: false,
           lock_strategy: :failed_attempts,
           maximum_attempts: 10,
           unlock_strategy: :both,
           unlock_in: 10.minutes

    before_validation :ensure_uid!
    before_save :ensure_authentication_token
    after_save :send_confirmation_if_directed

    # People are often invited into the system in batches or after offline contact.
    # set user.defer_confirmation to a true or call user.defer_confirmation! +before saving+
    # if you want to create a user account without sending out any messages yet.
    #
    # When you do want to invite that person, call user.resend_confirmation_token or
    # set the send_confirmation flag on a save.
    #
    # defer_confirmation is also set by remote services that send out their own invitations,
    # eg. when a new user is invited to screen an application round.
    #
    attr_accessor :defer_confirmation, :send_confirmation, :confirming

    # send_confirmation_notification? is called by devise's immediate confirmation mechanism.
    # If the defer_confirmation flag has been set as usual, we postpone.
    #
    def send_confirmation_notification?
      super && really_send_confirmation?
    end

    def really_send_confirmation?
      !defer_confirmation?
    end

    def defer_confirmation!
      self.defer_confirmation = true
    end

    def defer_confirmation?
      defer_confirmation && defer_confirmation != "false"
    end

    # send_confirmation? is called after save by our own later confirmation mechanism.
    # If the send_confirmation flag has been set, we confirm.
    #
    def send_confirmation!
      self.send_confirmation = true
    end

    def send_confirmation?
      send_confirmation && send_confirmation != "false"
    end

    # Only invoke password-confirmation validation when a password is being set.
    #
    def password_required?
      confirmed? && (!password.blank?)
    end

    def password_set?
      encrypted_password?
    end

    def lacks_password?
      !password_set?
    end

    ## Session ID
    #
    # Allows us to invalidate a session by remote control when the user signs out on a satellite site.

    def reset_session_id!
      token = generate_authentication_token
      self.update_column(:session_id, token)
      token
    end

    def clear_session_id!
      self.update_column(:session_id, "")
    end

    # Tell devise to tell warden to salt the session cookie with our session_id.
    # If the session_id changes, eg due to remote logout, the session will no longer succeed in describing a user.
    def authenticatable_salt
      session_id.presence || reset_session_id!
    end

    ## Auth tokens
    #
    # Are no longer native to devise but we use them for domain-cookie auth.

    def authenticate_token(token)
      Devise.secure_compare(self.authentication_token, token)
    end

    def reset_authentication_token!
      token = generate_authentication_token
      self.update_column(:authentication_token, token)
      token
    end

    def ensure_authentication_token
      if authentication_token.blank?
        self.authentication_token = generate_authentication_token
      end
      authentication_token
    end

    def confirmed=(value)
      self.confirmed_at = Time.now if value.present? and value != "false"
    end

    def password_match?
      self.errors[:password] << "can't be blank" if password.blank?
      self.errors[:password_confirmation] << "can't be blank" if password_confirmation.blank?
      self.errors[:password_confirmation] << "does not match password" if password != password_confirmation
      password == password_confirmation && !password.blank?
    end

    scope :unconfirmed, -> { where("confirmed_at IS NULL") }
    scope :administrative, -> { where(:admin => true) }
    scope :this_month, -> { where("created_at > ?", Time.now - 1.month) }
    scope :this_week, -> { where("created_at > ?", Time.now - 1.week) }

    scope :in_name_order, -> {
      order("family_name ASC, given_name ASC")
    }

    ## Organisation affiliation
    #
    belongs_to :organisation
    has_many :organisations, :foreign_key => :owner_id

    ## Group memberships
    #
    has_many :memberships, :dependent => :destroy
    has_many :groups, :through => :memberships
    has_many :mailing_list_memberships, :through => :memberships

    scope :in_any_directory_group, -> {
      joins(:groups).where(droom_groups: {directory: true}).group("droom_users.id")
    }

    scope :confirmed_accounts, -> {
      where('confirmed_at is not NULL')
    }

    scope :unconfirmed_accounts, -> {
      where('confirmed_at is NULL')
    }

    scope :in_specific_group, -> group_name {
      joins(:groups)
      .where(droom_groups: {name: group_name})
    }


    def admit_to(groups)
      groups = [groups].flatten
      groups.each do |group|
        memberships.where(group_id: group.id).first_or_create
      end
    end

    def expel_from(group)
      memberships.of_group(group).destroy_all
    end

    def member_of?(group)
      group && memberships.of_group(group).any?
    end

    def membership_of(group)
      memberships.find_by(group_id: group.id)
    end

    scope :in_group, -> group {
      group = group.id if group.is_a? Droom::Group
      select("droom_users.*")
        .joins("INNER JOIN droom_memberships as dm ON droom_users.id = dm.user_id")
        .where("dm.group_id" => group)
    }

    ## Event invitations
    #
    has_many :invitations, :dependent => :destroy
    has_many :events, :through => :invitations

    def invite_to(event)
      invitations.where(event_id: event.id).first_or_create if event && invitable?
    end

    def uninvite_from(event)
      invitations.to_event(event).destroy_all
    end

    def invited_to?(event)
      event && !!invitation_to(event)
    end

    def invitation_to(event)
      invitations.to_event(event).first
    end

    def invitable?
      email?
    end

    scope :personally_invited_to_event, -> event {
      joins('LEFT OUTER JOIN droom_invitations on droom_users.id = droom_invitations.user_id').where('droom_invitations.group_invitation_id is null AND droom_invitations.event_id = ?', event.id)
    }


    ## Folder permissions
    #
    # To simplify the business of showing and listing documents, we have adopted the convention that all
    # documents live in a folder. User accounts have links to those folders through the very thin
    # PersonalFolder joining class, and at the view level we only ever show folder and subfolder lists.
    # The only place we ever need a list of all the documents visible to this person is when searching, and
    # for that we use the Document.visible_to scope, usually by way of the #documents method defined below.
    #
    # Personal folders are created and destroyed along with invitations and memberships.
    #
    # BEWARE: This whole mechanism is largely superseded now by a much simpler confidentiality flag.
    # It proved too onerous in the administration and makes permission checks quite expensive.
    # The whole personal folder / dropbox folder machinery is likely to be deprecated soon.
    #
    has_many :personal_folders
    has_many :folders, :through => :personal_folders

    def add_personal_folders(folders=[])
      self.folders << folders if folders
    end

    def remove_personal_folders(folders=[])
      self.folders.delete(folders) if folders
    end

    def find_or_add_personal_folders(folders=[])
      folders = [folders].flatten
      folders.each do |folder|
        self.folders << folder unless self.folders.include?(folder)
      end
    end

    def has_folder?(folder)
      folder && personal_folders.of_folder(folder).any?
    end

    def documents
      Document.visible_to(self)
    end


    ## Dropbox links
    #
    has_many :dropbox_tokens, :foreign_key => "created_by_id"
    has_many :dropbox_documents

    def dropbox_token
      unless @dropbox_token
        @dropbox_token = dropbox_tokens.by_date.last || 'nope'
      end
      @dropbox_token unless @dropbox_token == 'nope'
    end

    def dropbox_client
      dropbox_token.dropbox_client if dropbox_token
    end


    ## Mugshot
    #
    has_attached_file :image,
                      :default_url => nil,
                      :styles => {
                        :standard => "520x520#",
                        :icon => "32x32#",
                        :thumb => "130x130#"
                      }

    do_not_validate_attachment_file_type :image

    def image_url(style=:original, decache=true)
      if image?
        url = image.url(style, decache)
        url.sub(/^\//, "#{Settings.protocol}://#{Settings.host}/")
      end
    end

    def image_url=(address)
      if address.present?
        begin
          self.image = open(address)
        rescue OpenURI::HTTPError => e
          Rails.logger.warn "Cannot read image url #{address} because: #{e}. Skipping."
        end
      end
    end

    def thumbnail
      image_url(:thumb)
    end

    def icon
      image_url(:icon)
    end


    ## Address book
    #
    # Can hold multiple emails, phones and addresses for each user.
    # Address book data is simple and always nested.
    #
    has_many :emails
    accepts_nested_attributes_for :emails, :allow_destroy => true
    has_many :phones
    accepts_nested_attributes_for :phones, :allow_destroy => true
    has_many :addresses
    accepts_nested_attributes_for :addresses, :allow_destroy => true

    # The only difficulty is to support devise login using any known email address.
    #
    scope :from_email, -> email {
      joins(:emails).where(droom_emails: {email: email})
    }

    def self.find_for_authentication(tainted_conditions={})
      from_email(tainted_conditions[:email]).first
    end

    # Confirmable and Recoverable both use the same resource-retrieval call so it is
    # not easy to to override find-by-email without also affecting find-by-confirmation_token.
    # Instead we just override the reset-sender.
    # NB. for useful-failure purposes we have to return a new user object with errors set.
    #
    def self.send_reset_password_instructions(attributes={})
      if user = from_email(attributes[:email]).first
        user.send_reset_password_instructions
      else
        user = new(email: attributes[:email])
        user.errors.add(:email, :not_found)
      end
      user
    end

    def active_for_authentication?
      emails.any?
    end

    def self.find_by_any_email(emails)
      from_email(emails).first
    end

    def email
      if email_record = emails.preferred.first
        email_record.email
      end
    end

    def email?
      emails.any?
    end

    def email=(email)
      add_email(email)
    end

    def add_email(email, address_type=nil)
      if email && email.present?
        if persisted?
          emails.where(email: email).first_or_create(address_type: address_type)
        else
          self.emails.build(email: email, address_type: address_type)
        end
      end
    end

    def address
      if address_record = addresses.preferred.first
        address_record.address
      end
    end

    def address?
      addresses.any?
    end

    def address=(address)
      add_address(address)
    end

    def correspondence_address=(address)
      add_address(address, AddressType.where(name: "Correspondence").first_or_create)
    end

    def add_address(address, address_type=nil)
      if address && address.present?
        if persisted?
          self.addresses.where(address: address).first_or_create(address_type: address_type)
        else
          self.phones.build(address: address, address_type: address_type)
        end
      end
    end

    def phone
      if phone_record = phones.preferred.first
        phone_record.phone
      end
    end

    def phone?
      phones.any?
    end

    def phone=(phone)
      add_phone(phone)
    end

    def mobile=(phone)
      add_phone(phone, AddressType.where(name: "Mobile").first_or_create)
    end

    def add_phone(phone, address_type=nil)
      if phone && phone.present?
        if persisted?
          self.phones.where(phone: phone).first_or_create(address_type: address_type)
        else
          self.phones.build(phone: phone, address_type: address_type)
        end
      end
    end



    ## Suggestion box
    #
    scope :matching, -> fragment {
      where('droom_users.given_name LIKE :f OR droom_users.family_name LIKE :f OR droom_users.chinese_name LIKE :f OR droom_users.title LIKE :f OR droom_users.email LIKE :f OR droom_users.phone LIKE :f OR CONCAT(droom_users.given_name, " ", droom_users.family_name) LIKE :f OR CONCAT(droom_users.family_name, " ", droom_users.given_name) LIKE :f', :f => "%#{fragment}%")
    }

    scope :matching_in_col, -> col, fragment {
      where("droom_users.#{col} LIKE :f", :f => "%#{fragment}%")
    }

    scope :matching_name, -> fragment {
      where("droom_users.family_name LIKE :f", :f => "%#{fragment}%")
    }

    scope :matching_email, -> fragment {
      joins(:emails).where("droom_emails.email LIKE :f", :f => "%#{fragment}%")
    }

    def as_suggestion
      {
        :type => 'person',
        :prompt => formal_name,
        :value => formal_name,
        :id => id
      }
    end

    def as_search_result
      {
        :type => 'person',
        :prompt => name,
        :value => name,
        :id => id
      }
    end


    # For select box
    #
    def self.for_selection
      self.published.map{|p| [p.name, p.id] }
    end


    ## Names
    #
    def title_ordinary?
      ['Mr', 'Ms', 'Mrs', '', nil].include?(title)
    end

    def title_if_it_matters
      title if title_ordinary?
    end

    def informal_name
      [given_name, family_name].join(' ')
    end
    alias :name :informal_name

    def formal_name
      if title_ordinary?
        informal_name
      else
        [title, family_name].join(' ')
      end
    end

    def colloquial_name
      [title_if_it_matters, informal_name].compact.join(' ')
    end

    def full_name
      [given_name, family_name].compact.join(' ')
    end

    def to_vcf
      @vcard ||= Vcard::Vcard::Maker.make2 do |maker|
        maker.add_name do |n|
          n.given = name || ""
        end
        maker.add_addr {|a|
          a.location = 'home' # until we do this properly with multiple contact sets
          a.country = post_country || ""
          a.region = post_region || ""
          a.locality = post_city || ""
          a.street = "#{post_line1}, #{post_line2}"
          a.postalcode = post_code || ""
        }
        maker.add_tel phone { |t| t.location = 'home' } unless phone.blank?
        maker.add_tel mobile { |t| t.location = 'cell' } unless mobile.blank?
        maker.add_email email { |e| t.location = 'home' }
      end
      @vcard.to_s
    end

    def self.vcards_for(users=[])
      users.map(&:vcf).join("\n")
    end


    ## Preferences
    #
    # User settings are held as an association with Preference objects, which are simple key:value pairs.
    # The keys are usually colon:separated for namespacing purposes, eg:
    #
    #   current_user.pref("email:enabled?")
    #   current_user.pref("dropbox:enabled?")
    #
    # Default settings are defined in Droom.user_defaults and can be defined in an initializer if the default droom
    # defaults are not right for your application.
    #
    # `User#pref(key)` returns the **value** of the preference (whether set or default) for the given key. It is intended
    # for use in views:
    #
    #   - if current_user.pref("dropbox:enabled?")
    #     = link_to "copy to dropbox", dropbox_folder_url(folder)
    #
    def pref(key)
      if pref = preferences.find_by(key: key)
        pref.value
      else
        Droom.user_default(key)
      end
    end

    def pref?(key)
      !!pref(key)
    end

    # `User#preference(key)` always returns a preference object and is used to build control panels. If no preference
    # is saved for the given key, we return a new (unsaved) one with that key and the default value.
    #
    def preference(key)
      pref = preferences.where(key: key).first_or_initialize
      pref.value = Droom.user_default(key) unless pref.persisted?
      pref
    end

    # Setting preferences is normally handled either by the PreferencesController or by nesting preferences
    # in a user form. `User#set_pref` is a convenient console method but not otherwise used much.
    #
    # Preferences are set in a simple key:value way, where key usually includes some namespacing prefixes:
    #
    #   user.set_pref("email:enabled", true)
    #
    def set_pref(key, value)
      preferences.where(key: key).first_or_create.set(value)
    end



    ## Permissions
    #
    # Permissions are usually assigned by way of group membership, but the effect of this is to create a user-permission
    # object. Additional user-permission objects can be created: all we need to do here is return that set.

    has_many :user_permissions
    has_many :permissions, :through => :user_permissions

    def permission_codes
      permissions.map(&:slug).compact.uniq
    end

    def permission_codes=(codes)
      #TODO
    end

    def permitted?(key)
      permission_codes.include?(key)
    end

    def permissions_elsewhere?
      permission_codes.select{|pc| pc !~ /droom/}.any?
    end

    def data_room_user?
      !Droom.require_login_permission || admin? || permitted?('droom.login')
    end


    ## Other ownership
    #
    has_many :scraps, :foreign_key => "created_by_id"
    has_many :documents, :foreign_key => "created_by_id"

    ## Search
    #
    searchkick callbacks: :async

    def search_data
      data = {
        id: id,
        uid: uid,
        title: title,
        name: name,
        chinese_name: chinese_name,
        emails: emails.map(&:email),
        addresses: addresses.map(&:address),
        phones: phones.map(&:phone),
        groups: group_slugs,
        liveliness: liveliness,
        privileged: privileged?
      }
      data.merge(additional_search_data)
    end

    def group_slugs
      groups.pluck(:slug).map(&:presence).compact.uniq
    end

    def status
      if admin?
        'admin'
      elsif privileged?
        'senior'
      elsif data_room_user?
        'internal'
      else
        'external'
      end
    end

    def liveliness
      if emails.empty?
        'unreachable'
      elsif !last_sign_in_at? and !confirmed_at?
        'unresponsive'
      elsif data_room_user?
        'internal'
      else
        'external'
      end
    end

    def privileged?
      admin? || groups.privileged.any?
    end

    def additional_search_data
      {}
    end

    def subsume(other_user)
      Droom::MergeUsersJob.perform_later(id, other_user.id, Time.now.to_i)
    end

    def subsume!(other_user)
      Droom::User.transaction do
        %w{emails phones addresses memberships organisations scraps documents invitations memberships user_permissions dropbox_tokens dropbox_documents personal_folders}.each do |association|
          self.send(association.to_sym) << other_user.send(association.to_sym)
        end
        %w{encrypted_password password_salt family_name given_name chinese_name title gender organisation_id description image}.each do |property|
          self.send "#{property}=".to_sym, other_user.send(property.to_sym) unless self.send(property.to_sym).present?
        end
        if self.merged_with?
          self.merged_with += "\n#{other_user.uid}"
        else
          self.merged_with = other_user.uid
        end
        save!
      end
    end

  protected

    def ensure_uid!
      self.uid = SecureRandom.uuid unless self.uid?
    end

    def send_confirmation_if_directed
      unless confirming # avoid the double hit caused by devise updating the confirmation token.
        self.confirming = true
        self.send_confirmation_instructions if email? && send_confirmation?
      end
    end

    def confirmed_if_password_set
      self.update_column(:confirmed_at, Time.now) if password_set? && !confirmed?
    end


  private

    def generate_authentication_token
      loop do
        token = Devise.friendly_token
        break token unless User.where(authentication_token: token).first
      end
    end

  end
end
