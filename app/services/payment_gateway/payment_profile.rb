module PaymentGateway
  class PaymentProfile
    attr_accessor :user, :address, :payment_method_nonce, :credit_card, :merchant_account_id,
                  :saved_card, :device_data, :verify_card, :reusable, :default, :options, :gateway, :business

    def initialize(user, address, payment_method, options = { supplier_id: nil, device_data: nil, reusable: true, payment_type: nil, storefront: nil, ip_address: nil })
      @business = user&.account&.storefront&.business
      @gateway = Configuration.new(business: @business, payment_type: get_payment_type(options)).gateway
      @user = user
      @address = address
      @options = options
      @payment_method_nonce = payment_method[:payment_method_nonce]
      @credit_card = payment_method.slice(:cc_cvv, :cc_exp_date, :cc_number)
      @merchant_account_id = get_merchant_account_id
      @device_data = options[:device_data]
      @reusable = options[:reusable].nil? ? true : options[:reusable]
      @default = payment_method[:default]
      @is_credit_card = credit_card?(options)

      # To facilitate testing, we skip card verification if a user has the api
      # developer role.
      @verify_card = !user.api_developer?
    end

    def save
      if @is_credit_card
        create_braintree_credit_card
      else
        create_braintree_payment_method
      end
      create_payment_profile
    end

    def braintree_customer_profile
      @braintree_customer_profile ||= user.braintree_customer_profiles.find_by(merchant_account_id: merchant_account_id)
      @braintree_customer_profile ||= create_braintree_customer
    end

    def create_braintree_payment_method
      customer_id = braintree_customer_profile.customer_id
      params = { customer_id: customer_id }
      params[:payment_method_nonce] = payment_method_nonce if payment_method_nonce

      result = gateway.payment_method.create(params)
      unless result.success?
        Rails.logger.warn("Create Payment Method Error for merchant #{merchant_account_id} with params: #{params}. Braintree API Error: #{result.inspect}")

        case params[:payment_type]
        when ::PaymentProfile::APPLE_PAY
          MetricsClient::Metric.emit('minibar_web.credit_card.error.create_payment_method.apple_pay', 1)
          raise API::Errors::ApplePayError
        when ::PaymentProfile::PAYPAL
          MetricsClient::Metric.emit('minibar_web.credit_card.error.create_payment_method.paypal', 1)
          raise API::Errors::PaypalError
        end

        MetricsClient::Metric.emit('minibar_web.credit_card.error.create_payment_method.other', 1)
        raise API::Errors::CreatePaymentMethodError
      end

      MetricsClient::Metric.emit('minibar_web.credit_card.error.create_payment_method', 0)
      @saved_card = result
    end

    def create_braintree_credit_card
      MetricsClient::Metric.emit('minibar_web.credit_card.create', 1)

      customer_id = braintree_customer_profile.customer_id
      params = braintree_credit_card.merge(customer_id: customer_id)
      params[:payment_method_nonce] = payment_method_nonce if payment_method_nonce

      result = gateway.credit_card.create(params)
      unless result.success?
        Rails.logger.warn("Credit Card Verification Error for merchant #{merchant_account_id} with params: #{params}. Braintree API Error: #{result.inspect}")
        MetricsClient::Metric.emit('minibar_web.credit_card.error.verification_error', 1)

        verification = result.credit_card_verification
        PaymentRejectionHistory.create(cardholder_name: address.name,
                                       street_address: address.address1,
                                       postal_code: address.zip_code,
                                       payment_method_nonce: payment_method_nonce,
                                       prevented: false,
                                       status: verification&.status,
                                       processor_response_type: verification&.processor_response_type,
                                       processor_response_code: verification&.processor_response_code,
                                       processor_response_text: verification&.processor_response_text,
                                       storefront: options[:storefront],
                                       ip_address: options[:ip_address])
        raise API::Errors::CardVerificationError
      end

      MetricsClient::Metric.emit('minibar_web.credit_card.error.verification_error', 0)
      @saved_card = result
    end

    def create_braintree_customer
      result = gateway.customer.create(braintree_customer_params)
      if result.success?
        MetricsClient::Metric.emit('minibar_web.credit_card.error.create_braintree_customer', 0)
        user.braintree_customer_profiles.create(merchant_account_id: merchant_account_id,
                                                customer_id: result.customer.id)
      else
        Rails.logger.info("Creating Braintree Customer Error #{braintree_customer_params}. Braintree API Error: #{result.inspect}")
        MetricsClient::Metric.emit('minibar_web.credit_card.error.create_braintree_customer', 1)

        raise API::Errors::CardError
      end
    end

    def create_payment_profile
      raise API::Errors::CardError if !saved_card && @is_credit_card
      raise API::Errors::ApplePayError if !saved_card && !@is_credit_card

      params = payment_profile_params
      if @is_credit_card
        card = saved_card&.credit_card
        card ||= saved_card.customer.credit_cards.last
        credit_card_params = translate_credit_card(card)
        params = params.merge(credit_card_params)
        params[:braintree_token] = card.token
        params[:payment_type] = options[:payment_type].presence || ::PaymentProfile::CREDIT_CARD
      else
        payment_method = saved_card&.payment_method
        payment_method_params = translate_payment_method(payment_method)
        params = params.merge(payment_method_params)
        params[:braintree_token] = payment_method.token
        params[:payment_type] = options[:payment_type]
      end

      if address.persisted? && address.payment_profile
        address.payment_profile.attributes = params
      else
        address.build_payment_profile(params)
      end
    end

    private

    def payment_profile_params
      {
        active: true,
        user: user,
        reusable: reusable,
        doorkeeper_application: address.doorkeeper_application,
        default: @default
      }
    end

    def translate_payment_method(payment_method)
      return {} unless payment_method

      # use #try because payment_method can be also Braintree::PayPalAccount
      # and it doesn't have the specifics of credit cards
      {
        cc_type: payment_method.try(:card_type),
        last_digits: payment_method.try(:last_4),
        month: payment_method.try(:expiration_month),
        year: payment_method.try(:expiration_year),
        bin: payment_method.try(:bin)
      }
    end

    def translate_credit_card(card)
      {
        cc_type: card.card_type,
        cc_kind: translate_credit_card_kind(card),
        first_name: card.cardholder_name,
        last_digits: card.last_4,
        month: card.expiration_month,
        year: card.expiration_year,
        bin: card.bin
      }
    end

    def translate_credit_card_kind(card)
      return ::PaymentProfile::CreditCardKind::DEBIT if card&.debit == Braintree::CreditCard::Debit::Yes
      return ::PaymentProfile::CreditCardKind::PREPAID if card&.prepaid == Braintree::CreditCard::Prepaid::Yes

      nil
    end

    def braintree_customer_params
      if user.liquidcommerce && user.liquidcommerce_email.present?
        return {
          first_name: user.first_name,
          last_name: user.last_name,
          email: user.liquidcommerce_email || user.dummy_email,
        }
      end

      {
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.dummy_email
      }
    end

    def braintree_credit_card
      params = {
        billing_address: braintree_billing_address,
        cardholder_name: address.name,
        options: braintree_options,
        device_data: device_data
      }

      unless payment_method_nonce
        params[:cvv] = credit_card[:cc_cvv]
        params[:expiration_date] = credit_card[:cc_exp_date]
        params[:number] = credit_card[:cc_number]
      end

      params
    end

    def braintree_billing_address
      {
        country_code_alpha2: 'US',
        extended_address: address.address2,
        locality: address.city,
        postal_code: address.zip_code,
        region: address.state_name,
        street_address: address.address1
      }
    end

    def braintree_options
      options = {
        make_default: true,
        verify_card: verify_card,
        verification_merchant_account_id: merchant_account_id
      }
      options.merge!({ verification_amount: '1.00' }) if Feature[:enable_verification_amount_one_dollar].enabled?
      options
    end

    def credit_card?(options)
      options[:payment_type].blank? || ::PaymentProfile::CREDIT_CARD_METHODS.include?(options[:payment_type])
    end

    def get_merchant_account_id
      return get_paypal_merchant_account_id if options[:paypal] && !business&.default_business?

      PaymentGateway::MerchantAccount.find_by_supplier_id(options[:supplier_id])
    end

    def get_paypal_merchant_account_id
      Settings.braintree.default_rb_merchant_account_id
    end

    def get_payment_type(options)
      return options[:payment_type] if options[:payment_type].present?

      ::PaymentProfile::CREDIT_CARD
    end
  end
end
