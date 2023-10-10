module Droom::Concerns::ControllerHelpers
  extend ActiveSupport::Concern

  included do
    protect_from_forgery if :html_request?
    helper Droom::DroomHelper

    rescue_from Droom::AccessDenied, :with => :not_authorized
    rescue_from CanCan::AccessDenied, :with => :not_allowed
    rescue_from Droom::PermissionDenied, :with => :not_allowed
    rescue_from Droom::ConfirmationRequired, :with => :prompt_for_confirmation
    rescue_from Droom::SetupRequired, :with => :prompt_for_setup
    rescue_from Droom::OrganisationRequired, :with => :prompt_for_organisation
    rescue_from Droom::OrganisationApprovalRequired, :with => :await_organisation_approval

    prepend_before_action :read_auth_cookie, except: [:cors_check]
    before_action :authenticate_user!, except: [:cors_check]
    before_action :set_exception_context

    before_action :check_user_is_confirmed, except: [:cors_check, :setup], unless: :devise_controller?
    before_action :check_user_setup, except: [:cors_check, :setup], unless: :devise_controller?
    before_action :check_user_has_organisation, except: [:cors_check, :setup_organisation], unless: :devise_controller?
    before_action :check_data_room_permission, except: [:cors_check, :set_password, :setup], unless: :devise_controller?

    before_action :note_current_user, except: [:cors_check]
    before_action :set_section, except: [:cors_check]
    before_action :set_access_control_headers

    skip_before_action :verify_authenticity_token, only: [:cors_check], raise: false
    after_action :update_auth_cookie, except: [:cors_check], unless: :api_controller?

    layout :no_layout_if_pjax
  end


  # Usually overridden in a base ApiController
  #
  def api_controller?
    false
  end

  def html_request?
    request.format.html?
  end

  # CORS blanket approval
  #
  def cors_check
    head :ok
  end

  def set_access_control_headers
    if request.env["HTTP_ORIGIN"].present? && Droom.cors_domains.empty? || Droom.cors_domains.include?(request.env["HTTP_ORIGIN"])
      headers['Access-Control-Allow-Origin'] = request.env["HTTP_ORIGIN"]
      headers["Access-Control-Allow-Credentials"] = "true"
      headers["Access-Control-Allow-Methods"] = %{DELETE, GET, PATCH, POST, PUT}
      headers['Access-Control-Request-Method'] = '*'
      headers['Access-Control-Allow-Headers'] = 'Origin, X-PJAX, X-Requested-With, X-ClientID, Content-Type, Accept, Authorization'
    end
  end


  ## Authorization helpers
  #
  # The droom auth cookie not an authentication mechanism, as Warden understands it, but a session store.
  # We check the cookie first, pull out a user value and populate the Warden session if we can.
  # This allows it to be retrieved with the usual fetch operation (as though it were local), which keeps
  # all our callbacks in the right places and allows us to distinguish between new and existing SSO logins.
  #
  def read_auth_cookie
    cookie = Droom::AuthCookie.new(warden.cookies)
    if cookie.valid? && cookie.fresh?
      if resource = Droom::User.where(unique_session_id: cookie.token).first
        if resource.valid_for_authentication?
          warden.session_serializer.store(resource, :user)
          warden.request.env['devise.skip_session_limitable'] = true
        end
      end
    end
  end

  def authenticate!
    if valid? && fresh? && resource && validate(resource)
      success!(resource)
    else
      cookie.unset
      pass
    end
  end

  def authenticate_user_if_possible(opts={})
    opts[:scope] = :user
    warden.authenticate(opts) if !devise_controller? || opts.delete(:force)
  end

  def admin?
    user_signed_in? && current_user.admin?
  end

  def organisation_admin?(organisation=nil)
    Droom::use_organisations? &&
      user_signed_in? &&
      current_user.admin? ||
      (current_user.organisation_admin? && !organisation || current_user.organisation == organisation)
  end

  def note_current_user
    if user_signed_in? && !devise_controller?
      RequestStore.store[:current_user] = current_user
      current_user.set_last_request_at!
    end
  end

  def check_data_room_permission
    if user_signed_in? && !devise_controller? && !api_controller?
      raise Droom::AccessDenied unless current_user.data_room_user?
    end
  end

  # For simplicity, we always update the auth cookie at the end of every request.
  # This avoids a whole mess of warden callback-sequencing and race conditions between devise modules.
  #
  def update_auth_cookie
    if user_signed_in? && current_user.unique_session_id?
      Rails.logger.warn "✅ setting auth_cookie after #{request.fullpath}"
      Droom::AuthCookie.new(warden.cookies).set(current_user)
    else
      Rails.logger.warn "⚠️ unsetting auth_cookie after #{request.fullpath}"
      Droom::AuthCookie.new(warden.cookies).unset
    end
  end

  ## Exception reporting
  #
  def set_exception_context
    # Honeybadger.context({
    #   :service => "Data room"
    # })
    # if current_user
    #   Honeybadger.context({
    #     :user_name => current_user.name,
    #     :user_uid => current_user.uid,
    #     :user_email => current_user.email
    #   })
    # end
  end


  ## Error responses
  #
  def not_authorized(exception)
    Rails.logger.warn "⚠️ not_authorized"
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/403.html", :status => :forbidden, :layout => false }
      format.js { head :unauthorized }
      format.json { head :unauthorized }
    end
  end

  def not_allowed(exception)
    Rails.logger.warn "⚠️ not_allowed"
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/403.html", :status => :forbidden, :layout => false }
      format.js { head :forbidden }
      format.json { head :forbidden }
    end
  end

  def not_found(exception)
    Rails.logger.warn "⚠️ not_found"
    @error = exception.message
    Honeybadger.notify(exception)
    respond_to do |format|
      format.html { render template: "errors/not_found", :status => 404 }
      format.js { head :not_found }
      format.json { head :not_found }
    end
  end


  ## User setup interruptions
  #  Post-registration or post-confirmation helpers to allow for late password-setting
  #  and any other configuration steps that should happen between confirmation and use of site.
  #
  def check_user_is_confirmed
    if user_signed_in? && !current_user.confirmed?
      raise Droom::ConfirmationRequired
    end
  end

  def prompt_for_confirmation
    Rails.logger.warn "⚠️ prompt_for_confirmation"
    render template: "/devise/registrations/confirm", locals: {resource: current_user}
  end

  def check_user_setup
    if user_signed_in? && (!current_user.encrypted_password? || !current_user.names?) && (!current_user.external_id?)
      @destination = request.fullpath
      raise Droom::SetupRequired
    end
  end

  def prompt_for_setup
    Rails.logger.warn "⚠️ prompt_for_setup"
    render template: "/droom/users/setup", locals: {user: current_user}
  end

  def check_user_has_organisation
    if user_signed_in? && Droom.use_organisations? && Droom.require_organisation?
      if !current_user.organisation
        @destination = request.fullpath
        raise Droom::OrganisationRequired

      elsif !current_user.organisation.approved?
        raise Droom::OrganisationApprovalRequired
      end
    end
  end

  def prompt_for_organisation
    Rails.logger.warn "⚠️ prompt_for_organisation"
    @organisations = Droom::Organisation.matching_email(current_user.email)
    render template: "/droom/users/setup_organisation"
  end

  def await_organisation_approval
    Rails.logger.warn "⚠️ await_organisation_approval"
    @organisations = Droom::Organisation.matching_email(current_user.email)
    render template: "/droom/users/await_organisation_approval"
  end


  ## Pagination helpers
  #
  def paginated(collection, default_show=10, default_page=1)
    @show = (params[:show] || default_show).to_i
    @page = (params[:page] || default_page).to_i
    collection.page(@page).per(@show)
  end

  def set_pagination_headers
    if results = instance_variable_get("@#{name_from_controller}")
      if results.respond_to? :total_count
        headers["X-Pagination"] = {
          limit: results.limit_value,
          offset: results.offset_value,
          total_count: results.total_count
        }.to_json
      end
    end
  end


  ## Subview selection

  def get_view
    @view = params[:view] if permitted_views.include? params[:view]
    @view ||= default_view
  end

  def permitted_views
    ['full', 'listed']
  end

  def default_view
    'full'
  end


  # Misc
  #
  def partial_exists?(path)
    lookup_context.find_all(path).any?
  end

  def set_section
    @section = controller_name.to_sym
  end

  def no_layout_if_pjax
    if pjax?
      @pjax = true
      false
    else
      @pjax = false
      default_layout
    end
  end

  def pjax?
    request.headers['X-PJAX'].present?
  end

  def default_layout
    Droom.config.layout
  end

end
