require 'rspec/core'
require 'action_controller'
require 'devise'

# Load the actual Devise controller without booting the legacy dummy application.
class ApplicationController < ActionController::Base
  include Devise::Controllers::Helpers
end

devise_path = Gem::Specification.find_by_name('devise').full_gem_path
$LOAD_PATH.unshift(File.join(devise_path, 'app/controllers'), File.join(devise_path, 'app/helpers'))
require 'devise_helper'
require 'devise_controller'
require 'devise/sessions_controller'

module Droom
  module Users; end
  module Concerns; end
end

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require_relative '../app/controllers/droom/concerns/flash_message_helper'
require_relative '../app/controllers/droom/users/sessions_controller'

RSpec.describe Droom::Users::SessionsController do
  let(:controller) { described_class.new }
  let(:cookie_jar) { {} }
  let(:cookie) { double(set: nil, unset: nil) }
  let(:user) { double('authenticated user') }
  let(:destination) do
    'https://croucher.org.hk/en/memo/study-awards-decisions-and-applicant-communications-83e23c0a8ea5c387cbf9e474468b6bce?embedded=child%2Bpage'
  end

  before do
    allow(controller).to receive(:cookies).and_return(cookie_jar)
    allow(controller).to receive(:params).and_return(ActionController::Parameters.new(backto: destination))
    allow(controller).to receive(:resource_name).and_return(:user)
    allow(controller).to receive(:set_alert)
    allow(controller).to receive(:set_notice)
    allow(controller).to receive(:t).and_return('Sign in')
    allow(Droom::AuthCookie).to receive(:new).and_return(cookie)
  end

  it 'returns a valid Warden session to the Memo even without a fresh shared cookie' do
    allow(controller).to receive(:current_user).and_return(user)
    expect(cookie).to receive(:set).with(user)
    expect(cookie).not_to receive(:fresh?)
    expect(controller).not_to receive(:sign_in)
    expect(controller).to receive(:redirect_to).with(destination, allow_other_host: true)
    controller.new
  end

  it 'replaces a stale return cookie with the explicitly requested destination and consumes it' do
    cookie_jar[:return_to] = '/old-page'
    expect(controller.determine_redirect_path).to eq(destination)
    expect(cookie_jar).not_to have_key(:return_to)
  end

  it 'shows the standard welcome sign-in page for a missing or expired Warden session' do
    allow(controller).to receive(:current_user).and_return(nil)
    allow(controller).to receive(:session).and_return({})
    allow(controller).to receive(:request).and_return(double(url: '/users/sign_in', referrer: nil))
    allow(controller).to receive(:warden).and_return(double(cookies: cookie_jar))
    stub_const('Droom::Page', Class.new)
    allow(Droom::Page).to receive(:published).and_return(double(find_by: double('welcome page')))
    allow(Droom).to receive(:page_layout).and_return('sign-in')
    expect(cookie).to receive(:unset)
    expect(controller).not_to receive(:sign_in)
    expect(controller).to receive(:render).with(template: 'droom/pages/published', layout: 'sign-in')
    controller.new
    expect(cookie_jar[:return_to]).to eq(destination)
  end

  it 'does not decode the already decoded query parameter a second time' do
    expect(controller.stored_location_for(:user)).to eq(destination)
    expect(controller.determine_redirect_path).to eq(destination)
  end

  it 'retains the requested destination after a failed sign-in' do
    allow(controller).to receive(:warden).and_return(double(authenticate: nil))
    allow(controller).to receive(:auth_options).and_return({})
    allow(controller).to receive(:new_user_session_url).and_return('/users/sign_in')
    expect(controller).to receive(:redirect_to).with('/users/sign_in')
    controller.create
    expect(cookie_jar[:return_to]).to eq(destination)
  end

  it 'uses the saved destination after a successful sign-in and clears it' do
    cookie_jar[:return_to] = destination
    allow(controller).to receive(:params).and_return(ActionController::Parameters.new)
    allow(controller).to receive(:resource_name).and_return(:user)
    allow(controller).to receive(:warden).and_return(double(authenticate: user))
    allow(controller).to receive(:auth_options).and_return({})
    allow(controller).to receive(:backup_email_login_blocked?).and_return(false)
    allow(controller).to receive(:flag_backup_email_sign_in)
    allow(user).to receive(:name).and_return('Test user')
    expect(controller).to receive(:sign_in).with(:user, user)
    expect(controller).to receive(:redirect_to).with(destination, allow_other_host: true)
    controller.create
    expect(cookie_jar).not_to have_key(:return_to)
  end

  it 'only permits Croucher HTTP(S) cross-host returns' do
    expect(controller.send(:croucher_return_url?, destination)).to be(true)
    expect(controller.send(:croucher_return_url?, 'https://data.croucher.org.hk/documents')).to be(true)
    %w[https://croucher.org.hk.evil.test https://evil.test //evil.test javascript:alert(1) https://user@croucher.org.hk/].each do |url|
      expect(controller.send(:croucher_return_url?, url)).to be(false)
    end
  end

  it 'lets the new action handle authenticated sessions rather than Devise redirecting early' do
    allow(controller).to receive(:action_name).and_return('new')
    callback = described_class._process_action_callbacks.find { |item| item.filter == :require_no_authentication }
    conditions = callback.instance_variable_get(:@unless)
    expect(conditions.any? { |condition| condition.match?(controller) }).to be(true)
  end
end
