class PaymentMethodCreationService
  include SentryNotifiable

  attr_reader :user, :doorkeeper_application

  def initialize(user, doorkeeper_application, _options = {})
    @user = user
    @doorkeeper_application = doorkeeper_application

    raise PaymentMethodError, 'User is invalid' unless @user
  end

  def create(params, address)
    cc_params = params.slice(:cc_number, :cc_exp_date, :cc_cvv, :payment_method_nonce, :default)
    other_payments_params = params.slice(:supplier_id, :device_data, :reusable, :payment_type, :storefront, :ip_address)
    PaymentGateway::PaymentProfile.new(user, address, cc_params, other_payments_params).save

    # Need to save the address here since PaymentGateway only builds the asociated
    # profile
    address.save

    address.payment_profile
  rescue API::Errors::CardVerificationError
    false
  rescue StandardError => e
    notify_sentry_and_log(e)
    false
  end
end

class PaymentMethodError < StandardError
  attr_reader :status, :detail

  def initialize(body, options = {})
    @status = options.delete(:status) || 500
    @detail = options
    @detail[:message] = body
    @detail[:name] ||= 'PaymentMethodError'
  end

  def to_s
    "#{@detail[:name]}: #{@detail[:message]}"
  end
end
