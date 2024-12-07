module Shared::Helpers::AddressHelpers
  # options[:required] = bool
  def get_address(options = {})
    address = Address.create_from_params(params)
    error!('No location provided.', 400) if options[:required] && address.nil?
    address
  end

  def address_params(params)
    clean_params(params).permit(:name, :company, :address1, :address2, :city, :latitude, :longitude,
                                :state_name, :zip_code, :phone, :billing_default, :default)
  end

  def validate_address_phone_requirement
    return unless storefront.default_storefront?

    error!({ name: 'ValidationError', message: 'Phone is required' }, 400) unless params.key?(:phone)
    error!({ name: 'ValidationError', message: 'Phone cannot be blank' }, 400) if params[:phone].blank?
  end

  def normalized_phone
    PhonyRails.normalize_number(params[:phone])
  end

  def handle_opt_in
    segment_service = Segments::SegmentService.from(storefront)

    if params[:sms_opt_in]
      segment_service.sms_identify(@user, normalized_phone)
      segment_service.sms_track(@user, normalized_phone)
      Attentive::SubscribeWorker.perform_async(@user.id, normalized_phone) if Feature[:attentive_subscription].enabled?

      @user&.update(sms_subscribed: true)
    end

    return unless params[:email_opt_in] && !@user.guest?

    segment_service.identify_email_capture(@user&.account&.email, @user)
    segment_service.track_email_capture(@user&.account&.email, @user)
    @user&.update(email_subscribed: true)
  end
end
