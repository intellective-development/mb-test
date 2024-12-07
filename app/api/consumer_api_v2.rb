# TODO: Find a new home
module ErrorFormatter
  def self.call(message, _backtrace, _options, _env, _original_exception)
    message = message[:error] if message.is_a?(Hash) && message[:error].present?
    message = { message: message } if message.is_a?(String)
    { error: message }.to_json
  end
end

require 'sentry/rack/capture_exceptions'
require 'doorkeeper/grape/helpers'

class ConsumerAPIV2 < BaseAPIV2
  require 'grape-swagger'

  helpers Doorkeeper::Grape::Helpers,
          Shared::Helpers::Auth0TokenHelpers,
          Shared::Helpers::PaymentPartners::Authenticatable

  before do
    soft_authenticate
  end

  use Sentry::Rack::CaptureExceptions

  format :json
  prefix 'api'
  version 'v2', using: :path

  error_formatter :json, ErrorFormatter

  helpers do
    include SentryNotifiable

    def authenticate!(user_id = nil)
      soft_authenticate(user_id)

      error!('Unauthorized', 403) if @user.nil?
      error!('Unauthorized', 403) if user_id && @user.id != user_id.to_i

      # TODO: Should we handle this in the user authentication module rather
      #       than here?
      error!('Unauthorized', 403) if @user.account&.canceled?
    end

    # Find the user that owns the access token
    def resource_owner
      User.find_by(account_id: doorkeeper_token.resource_owner_id) if doorkeeper_token.resource_owner_id
    end

    def soft_authenticate(_user_id = nil)
      unless request.path.include?('/auth/') || request.path.include?('/storefront_checkout/')
        doorkeeper_authorize!

        @user ||= begin
          user = if liquid_headers?
                   find_liquid_user
                 else
                   resource_owner || User.authenticate_with_token(headers['X-Minibar-User-Token'])
                 end

          Sentry.set_user(id: user.id, email: user.email, name: user.name) if user

          user
        end
      end
    end

    def find_liquid_user
      user_data = user_data_from_token(headers['X-Liquid-Access-Token'], storefront)
      user = RegisteredAccount.find_by(
        uid: user_data[:uid], provider: user_data[:provider], storefront: storefront
      )&.user

      Rails.logger.error("User not found for uid: #{user_data[:uid]} and provider: #{user_data[:provider]}") unless user

      user
    end

    def liquid_headers?
      headers['X-Liquid-Id-Token'] && headers['X-Liquid-Access-Token']
    end

    def new_mobile_app?
      String(request.env['HTTP_X_MINIBAR_CLIENT_VERSION']).starts_with?('3.')
    end

    def device_id
      request.env['HTTP_X_MINIBAR_DEVICE_ID'] || request.env['HTTP_X_MINIBAR_AD_ID']
    end

    def validate_device_udid!
      error!('Minibar is currently unavailable. Please try again later (Error Code: 423)', 403) if DeviceBlacklist.blacklisted?(device_id)
    end

    def client_ip
      env['HTTP_CF_CONNECTING_IP'] || env['action_dispatch.remote_ip']
    end

    def original_client_ip_or_remote_ip
      env['HTTP_X_ORIGINAL_CLIENT_IP'] || client_ip
    end

    def client_details
      @client_details ||= ClientDetails.new(request, doorkeeper_token)
    end

    def doorkeeper_application
      doorkeeper_token&.application
    end

    def storefront
      return @storefront if @storefront.present?

      app = doorkeeper_application
      @storefront = Storefront.find_by(oauth_application_id: app.id) if app.present?
      # We can also consider raising exception instead of falling back to Minibar storefront
      @storefront = Storefront.find(Storefront::MINIBAR_ID) unless @storefront.present?
      @storefront
    end

    def clean_params(params)
      ActionController::Parameters.new(params)
    end

    def current_visit
      nil
    end

    def complete_address
      return unless params[:address] && params[:address][:zip_code].present?

      # TODO: Consider replacing the area gem with microservice for better performance, the initial load of the
      # csv data is expensive.
      params[:address][:city]  = params[:address][:zip_code].to_region(city: true)   if params[:address][:city].blank?
      params[:address][:state] = params[:address][:zip_code].to_region(state: true)  if params[:address][:state].blank?

      error!({ name: 'ValidationError', message: 'City is required' }, 400) if params[:address][:city].blank?
    end

    def invalid_card_response
      Rack::Response.new(
        {
          error: {
            message: 'There was an issue processing your credit card.',
            name: 'InvalidCard'
          }
        }.to_json, 400, 'Content-Type' => 'application/json'
      )
    end
  end

  before do
    Sentry.set_extras(client_details: client_details.to_h)
  end

  rescue_from Grape::Exceptions::ValidationErrors do |e|
    # TODO: Figure out a better way to do this.
    if e.message.include?('coupons are mutually exclusive')
      message = Array('Please user either gift_card and promo_code structure or coupons structure, not both.')
    elsif e.message.include?('are mutually exclusive')
      message = Array('Please pass either a Credit Card or Payment Method Nonce, not both.')
    elsif e.message.include?('email, password provide all or none of parameters')
      message = Array('Please provide an email address and password.')
    elsif e.message.include?('password, password_confirmation provide all or none of parameters')
      message = Array('Please provide a password and password confirmation.')
    elsif e.message.include?('number, storefront_uuid provide all or none of parameters')
      message = Array('Please provide an order number and storefront UUID or none of them')
    elsif e.message.include?('provide all or none of parameters')
      message = Array('Card number, expiry date and security code are all required.')
    else
      message = String(e.message.split(',')[0]).split(' ')

      message[0] = case message[0]
                   when 'gift_options[recipient_name]' then 'Gift recipient'
                   when 'gift_options[recipient_phone]' then 'Gift recipient phone number'
                   when 'gift_options[message]' then 'Gift message'
                   when 'gift_options[0][recipient_name]' then 'Gift recipient'
                   when 'gift_options[0][recipient_phone]' then 'Gift recipient phone number'
                   when 'gift_options[0][message]' then 'Gift message'
                   when 'cc_number' then 'Credit card number'
                   when 'cc_exp_date' then 'Expiration date'
                   when 'cc_cvv' then 'Security code'
                   when 'address[name]' then 'Name'
                   when 'address[address1]' then 'Street address'
                   when 'address[address2]' then 'Address 2'
                   when 'address[city]' then 'City'
                   when 'address[state]' then 'State'
                   when 'address[zip_code]' then 'Zip code'
                   when 'address[phone]' then 'Phone'
                   when 'address1' then 'Street Address'
                   when 'address2' then 'Address 2'
                   when 'order_items[0][id]' then 'Item'
                   when 'order_items[0][quantity]' then 'Quantity'
                   when 'shipping_address_id' then 'Shipping address'
                   when 'payment_profile_id' then 'Payment profile'
                   when 'payment_method_nonce' then 'Payment method'
                   else message[0]
                   end
    end

    Rack::Response.new({
      error: {
        name: 'ValidationError',
        message: message.join(' ').humanize
      }
    }.to_json, e.status, 'Content-Type' => 'application/json')
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    notify_sentry_and_log(e)

    message = e.message.downcase.capitalize
    Rack::Response.new(
      [{ error: {
        name: 'ValidationError',
        message: message
      } }.to_json],
      400,
      'Content-Type' => 'application/json'
    )
  end

  rescue_from API::Errors::ApplePayError do |e|
    notify_sentry_and_log(e)

    Rack::Response.new({
      error: {
        message: 'We were unable to verify your apple pay information. Please try again, or try another payment method.',
        name: 'InvalidApplePay'
      }
    }.to_json, 400, 'Content-Type' => 'application/json')
  end

  rescue_from API::Errors::CardVerificationError do |_e|
    # we skip to raise this exception to Sentry
    invalid_card_response
  end

  rescue_from API::Errors::CardError do |e|
    notify_sentry_and_log(e)

    invalid_card_response
  end

  DOC_AUTH_HEADER = {
    headers: {
      'Authorization' => {
        description: 'OAuth access token',
        required: true
      },
      'X-Minibar-User-Token' => {
        description: 'The users\'s Minibar token. This is unnecessary if the access token provided in the Authorization header was provided by the OAuth Authorization Grant flow (since it is already associated with a user). For non-user or order centric endpoints, this is optional.',
        required: false
      }
    }
  }.freeze

  mount ConsumerAPIV2::AppDownloadEndpoint
  mount ConsumerAPIV2::AuthenticationEndpoint
  mount ConsumerAPIV2::AuthorizerEndpoint
  mount ConsumerAPIV2::AutocompleteEndpoint
  mount ConsumerAPIV2::BillingEndpoint
  mount ConsumerAPIV2::CartEndpoint
  mount ConsumerAPIV2::ClientEndpoint
  mount ConsumerAPIV2::CocktailsEndpoint
  mount ConsumerAPIV2::ContentEndpoint
  mount ConsumerAPIV2::CouponEndpoint
  mount ConsumerAPIV2::DeliverabilityEndpoint
  mount ConsumerAPIV2::DeliveryMethodEndpoint
  mount ConsumerAPIV2::FeedbackEndpoint
  mount ConsumerAPIV2::GiftCardEndpoint
  mount ConsumerAPIV2::GiftCardImagesEndpoint
  mount ConsumerAPIV2::GiftEndpoint
  mount ConsumerAPIV2::MembershipPlansEndpoint
  mount ConsumerAPIV2::MembershipsEndpoint
  mount ConsumerAPIV2::OrdersEndpoint
  mount ConsumerAPIV2::OrderSurveyEndpoint
  mount ConsumerAPIV2::PickupEndpoint
  mount ConsumerAPIV2::PingEndpoint
  mount ConsumerAPIV2::ProductGroupingEndpoint
  mount ConsumerAPIV2::ProductsEndpoint
  mount ConsumerAPIV2::RegionsEndpoint
  mount ConsumerAPIV2::SchedulingEndpoint
  mount ConsumerAPIV2::SessionEndpoint
  mount ConsumerAPIV2::ShippingEndpoint
  mount ConsumerAPIV2::StorefrontsEndpoint
  mount ConsumerAPIV2::SubscriptionsEndpoint
  mount ConsumerAPIV2::SuppliersEndpoint
  mount ConsumerAPIV2::UserEndpoint
  mount ConsumerAPIV2::WaitlistEndpoint

  mount ConsumerAPIV2::Orders::PaymentMethodEndpoint
  mount ConsumerAPIV2::PaymentPartners::AuthorizationToken
  mount ConsumerAPIV2::GuestUsersEndpoint

  add_swagger_documentation(
    doc_version: '1.0.0',
    info: {
      title: 'Minibar API',
      description: 'Enable alcohol commerce with the Minibar API and provide your users with the ability to order drinks on demand from within your web or mobile application.',
      contact_name: 'Chris Korhonen',
      contact_email: 'chris@minibardelivery.com',
      contact_url: 'https://minibardelivery.com',
      terms_of_service_url: 'https://minibardelivery.com/terms'
    },
    format: :json, # need to specify json for ui to work
    hide_documentation_path: true,
    api_version: 'v2'
  )
end
