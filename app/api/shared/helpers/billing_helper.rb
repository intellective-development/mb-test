module Shared::Helpers::BillingHelper
  def billing_address_params(params)
    clean_params(params[:address]).permit(:name, :address1, :address2, :city, :state_name,
                                          :zip_code, :phone, :billing_default, :default)
  end

  def validate_and_create_payment_profile(params, user)
    convert_payment_type_params

    if Feature[:validate_rejection_history].enabled? &&
       PaymentRejectionHistory.scam?(params[:cardholder_name], params[:address1], params[:zip_code])
      Rails.logger.warn('Rejection scam detected')
      save_rejection
      error!(no_payment_profile_error_msg, 400)
    end

    temp_params = billing_address_params(params)
    temp_params[:address_purpose] = :billing
    temp_params[:billing_default] = user.default_billing_address.nil?
    temp_params[:name] = 'no name included' if temp_params[:name].blank?

    address = AddressCreationService.new(user, doorkeeper_application).create(temp_params)
    unless address
      save_rejection(prevented: false, text: "Invalid address: #{temp_params}")
      error!(no_payment_profile_error_msg, 400)
    end

    sleep 3.seconds if Feature[:delay_cc].enabled?

    payment_method_params = params.slice(:cc_number, :cc_exp_date, :cc_cvv, :default, :payment_method_nonce,
                                         :supplier_id, :device_data, :payment_type)
                                  .merge(storefront: storefront, ip_address: request.remote_ip)

    result = PaymentMethodCreationService.new(user, doorkeeper_application).create(payment_method_params, address)

    audit = {}
    audit[:approved] = result ? true : false

    audit = audit.merge(params.slice(:cc_number, :cc_exp_date, :cc_cvv, :default, :payment_method_nonce, :supplier_id, :payment_type, :url))
                 .merge(ip_address: request.remote_ip,
                        storefront_name: storefront&.name,
                        user_id: user.id,
                        address_id: address.id)

    Rails.logger.warn("PaymentMethodCreationService.create: #{audit}")
    result
  end

  def save_rejection(prevented: true, text: nil)
    PaymentRejectionHistory.create(cardholder_name: params[:address][:name],
                                   street_address: params[:address][:address1],
                                   postal_code: params[:address][:zip_code],
                                   payment_method_nonce: params[:payment_method_nonce],
                                   processor_response_text: text,
                                   prevented: prevented,
                                   storefront: storefront,
                                   ip_address: request.remote_ip)
  end

  def no_payment_profile_error_msg
    case params[:payment_type]
    when ::PaymentProfile::APPLE_PAY
      'We were unable to verify your apple pay information. Please try again, or try another payment method.'
    when ::PaymentProfile::PAYPAL
      'We were unable to verify your paypal information. Please try again, or try another payment method.'
    else
      'We were unable to verify your credit card information. Please verify your card details and billing address, or try another card.'
    end
  end

  def convert_payment_type_params
    params[:payment_type] = ::PaymentProfile::APPLE_PAY if params[:apple_pay]
    params[:payment_type] = ::PaymentProfile::PAYPAL if params[:paypal]
  end
end
