class CustomerNotifier < BaseNotifier
  def waitlist_notification(zipcode_waitlist_id)
    @email = ZipcodeWaitlist.find(zipcode_waitlist_id).try(:email)

    unless @email.nil?
      mail(to: @email, from: 'Minibar Delivery <info@minibardelivery.com>', subject: format_subject('You’re On Our List!')) do |format|
        format.html { render layout: 'email_ink' }
      end
    end
  end

  def new_referral_credits(referral_id)
    @referral = Referral.find(referral_id)
    @user = @referral.referring_user
    return unless @user.minibar?

    @referral_user = @referral.referral_user
    @coupon        = Coupon.find(@referral.coupon_id)

    mail(to: @user.email_address_with_name, subject: format_subject("You've Earned $10 Off Your Next Order")) do |format|
      format.html { render layout: 'email_ink' }
    end
  end

  def order_customer_service_comment(order_id, message)
    @order      = Order.find(order_id)
    @recipient  = User.find(@order.user.id)
    @to         = "\"#{@recipient.name}\" <#{@order.storefront.default_storefront? ? @recipient.email : @order.email}>"
    @from       = "#{@order.storefront.name} <#{@order.storefront.support_email}>"
    @subject    = "Your #{@order.storefront.name} Order (##{@order.number})"
    @message    = message

    mail(to: @to,
         from: @from,
         subject: @subject) do |format|
      format.html { render layout: 'email_ink' }
    end
  end

  def order_confirmation(order_id)
    @order = Order.includes(:user, :ship_address).find(order_id)
    return unless @order.minibar?

    @user       = @order.user
    @gift_order = @order.gift?

    @ondemand_message    = TopBannerMessage.find_or_initialize_by(id: 3)
    @shipping_message    = TopBannerMessage.find_or_initialize_by(id: 4)
    @pickup_message      = TopBannerMessage.find_or_initialize_by(id: 5)

    # TODO: Why are we creating this object? Why can't this be handled in the template?
    @order_cost = {
      Subtotal: @order.sub_total,
      Delivery: @order.shipping_charges == 0.0 ? 'FREE' : @order.shipping_charges,
      Tax: @order.amounts.sales_tax
    }
    discount = @order.discounts_total
    @order_cost[:Tip]            = @order&.tip_amount if @order.shipping_methods.where(allows_tipping: true).exists?
    @order_cost['Bottle Fee']    = @order&.bottle_deposits.to_f.abs if @order.bottle_deposits > 0.0
    @order_cost['Bag Fee']       = @order&.bag_fee.to_f.abs if @order.bag_fee > 0.0
    @order_cost['Engraving Fee'] = @order&.engraving_fee.to_f.abs if @order.engraving_fee > 0.0
    @order_cost[:Discounts]      = -discount.to_f.abs unless discount.zero?
    @order_cost['Service Fee*']  = @order.service_fee.to_f.abs unless @order.service_fee.zero?
    @order_cost[:Total]          = @order.taxed_total
    @loyalty_program_module_content = EmailBannerService.new(:order_confirmation, @user).build if LoyaltyProgramTester.loyalty_program_tester?(@user.email)

    grouping_permalinks = @order.product_size_groupings.map(&:permalink).flatten
    brand_permalinks = @order.brands.map(&:permalink).flatten
    permalinks = grouping_permalinks + brand_permalinks
    @bottom_banner = TopBannerMessage.active.confirmation_email_bottom_banner
    @bottom_banner_filtered = TopBannerMessage.active.confirmation_email_bottom_banner_with_permalinks_filter
    @bottom_banner_filtered = nil unless @bottom_banner_filtered&.includes_permalink?(permalinks)

    mail(to: @user.email_address_with_name, subject: format_subject('Order Confirmation')) do |format|
      format.html { render layout: 'email_foundation_2' }
    end
  end

  def shipment_shipping_confirmation(shipment_id)
    @shipment = Shipment.includes(order: [:user]).find(shipment_id)
    @order = @shipment.order
    return unless @order.minibar?

    @user            = @order.user
    @gift_card_order = @order.order_items.load_target.sum { |item| Variant.gift_card?(item.variant_id) ? 1 : 0 } == @order.order_items.count

    mail(to: @user.email_address_with_name, subject: format_subject('Shipping Confirmation')) do |format|
      format.html { render layout: 'email_foundation_2' }
    end
  end

  def shipment_pickup_confirmation(shipment_id)
    @shipment = Shipment.includes(order: [:user]).find(shipment_id)
    @order = @shipment.order
    return unless @order.minibar?

    @user = @order.user

    mail(to: @user.email_address_with_name, subject: format_subject('Your Order is Ready for Pickup')) do |format|
      format.html { render layout: 'email_foundation_2' }
    end
  end

  def order_survey(order_id)
    @order = Order.includes(:user).find(order_id)
    return unless @order.minibar?

    @order_survey = @order.order_survey

    if @order_survey&.pending?
      subject_line = @order.gift? ? 'Rate your gift order' : 'Rate your Minibar Delivery'
      mail(to: @order.user.email_address_with_name, subject: format_subject(subject_line)) do |format|
        format.html { render layout: 'email_foundation_2' }
      end
    end
  end

  def shipment_gift_delivered(shipment_id)
    @shipment = Shipment.includes(order: :user).find(shipment_id)
    @order    = @shipment.order
    return unless @order.minibar?

    @user = @order.user
    return unless @order.gift?

    mail(to: @user.email_address_with_name, subject: format_subject('Gift Order Delivery Confirmation')) do |format|
      format.html { render layout: 'email_ink' }
    end
  end

  def late_order(order_id)
    @order = Order.find(order_id)
    return unless @order.minibar?

    @user          = @order.user
    late_shipments = @order.shipments.where(late: true)
    @late_products = late_shipments.flat_map { |shipment| shipment.order_items.collect(&:product) }

    mail(to: @user.email_address_with_name, subject: format_subject('We\'re Running a Bit Behind Schedule...')) do |format|
      format.html { render layout: 'email_ink' }
    end
  end

  def order_cancellation(order_id)
    @order = Order.includes(:order_amount).find(order_id)
    return unless @order.minibar?

    @user = @order.user

    mail(to: @user.email_address_with_name, subject: format_subject('Order Cancellation')) do |format|
      format.html { render layout: 'email_ink' }
    end
  end

  def scheduled_order_reminder(order_id)
    @order = Order.includes(:user).find(order_id)
    return unless @order.minibar?

    @user       = @order.user
    @gift_order = false
    @order_cost = {
      Subtotal: @order.sub_total,
      Delivery: @order.shipping_charges.zero? ? 'FREE' : @order.shipping_charges,
      Tax: @order.taxed_amount,
      Tip: @order.tip_amount
    }
    discount = @order.discounts_total
    @order_cost[:Discounts] = -discount.to_f.abs unless discount.zero?
    @order_cost[:Total] = @order.taxed_total
    @scheduled_shipments = @order.shipments.select(&:scheduled_for)

    mail(to: @user.email_address_with_name, subject: format_subject('Your Minibar Delivery order is scheduled to arrive today')) do |format|
      format.html { render layout: 'email_ink' }
    end
  end

  def prompt_app_review(order_survey_id)
    @survey = OrderSurvey.includes(:user).find(order_survey_id)
    @user   = @survey.user
    return unless @user.minibar?

    mail(to: @user.email_address_with_name, subject: format_subject('We Want to Hear from You!')) do |format|
      format.html { render layout: 'email_ink' }
    end
  end

  def post_order_email(order_id, post_order_email_id)
    @order = Order.find(order_id)
    return unless @order.minibar?

    @post_order_email = PostOrderEmail.find(post_order_email_id)

    return true if @post_order_email.tag_name == 'beam-gifting' && !@order.gift?

    mail(to: @order.user.email_address_with_name,
         subject: @post_order_email.subject,
         template_path: 'post_order_emails',
         template_name: @post_order_email.template_slug)
  end

  def prize_logic(one_time_code_id)
    one_time_code = OneTimeCode.find(one_time_code_id)

    @recipient_email = one_time_code.metadata['recipient']
    @target_url      = one_time_code.metadata['message_url']
    @order           = one_time_code.order
    return unless @order.minibar?

    mail(to: @recipient_email, subject: format_subject("#{@order.user.first_name} took a shot at making your holidays better.")) do |format|
      format.html { render layout: 'email_ink' }
    end
  end

  def cart_abandonment(order_id, cart_share_id)
    @order = Order.find(order_id)
    return unless @order.minibar?

    @cart_share = CartShare.includes(:cart_share_items).find(cart_share_id)
    @user = @cart_share.user
    @offer = EmailBannerService.new(:cart_abandonment, @user).build if @user.number_of_finished_orders <= 1

    test_group = @user.get_test_group > 50 ? 0 : 1
    subject = test_group.zero? ? 'Baby Come Back' : 'Still Thinking It Over?'
    email = mail(to: @user.email_address_with_name, subject: format_subject(subject)) do |format|
      format.html { render layout: 'email_foundation_2' }
    end

    email.mailgun_options = {
      campaign: 'cart_abandonment',
      tag: "cart_abandonment_test_#{test_group}"
    }

    email
  end

  def loyalty_reward(user_id)
    @user = User.find(user_id)

    raise 'Loyalty reward could only be used for Minibar storefront' unless @user.account.storefront.default_storefront?

    @coupon_code = CouponValue.generate_loyalty_reward(@user.account.storefront).code
    mail(to: @user.email_address_with_name, subject: format_subject('Take $5 off your next Minibar Delivery')) do |format|
      format.html { render layout: 'email_ink' }
    end
  end

  def gift_card(coupon_id)
    @coupon = Coupon.find(coupon_id)
    return unless @coupon.minibar?

    @gift_card_item = @coupon.order_item
    permalink       = @gift_card_item.variant.product_size_grouping.permalink

    @banner_src = 'email/gift_card/email-banner.png'
    @image_src =  case permalink
                  when 'gift-card-congrats'
                    'email/gift_card/congrats.png'
                  when 'gift-card-birthday'
                    'email/gift_card/birthday.png'
                  when 'gift-card-thanks'
                    'email/gift_card/thank-you.png'
                  when 'gift-card-happy-holidays'
                    'email/gift_card/happy-holidays.png'
                  when 'gift-card-merry-christmas'
                    'email/gift_card/merry-christmas.png'
                  when 'gift-card-happy-hanukkah'
                    'email/gift_card/happy-hanukkah.png'
                  when 'gift-card-happy-new-year'
                    'email/gift_card/happy-new-year.png'
                  else
                    'email/gift_card/classic.png'
                  end

    favorite_ids = %w[johnnie-walker-blue don-julio-1942-tequila maker-s-mark veuve-clicquot-yellow-label suntory-whisky-toki cloudy-bay-pinot-noir hornitos-plata grand-marnier-cuvee-louis-alexandre ardbeg-islay-10-year-single-malt]
    @favorites = favorite_ids.collect { |id| ProductGrouping.find_by(permalink: id) }.flatten.compact

    mail(to: @coupon.recipient_email, subject: format_subject("You've received an eGift card")) do |format|
      format.html { render layout: 'email_ink' }
    end
  end

  def update_payment_profile_link(order)
    @storefront = order.storefront
    recipient = User.find(order.user_id)

    message_params = {
      customer_name: recipient.name,
      payment_link: order.payment_profile_update_link.url,
      expire_at_info: "#{expire_at_in_days(order.payment_profile_update_link.expire_at)} days"
    }

    to = "\"#{recipient.name}\" <#{order.storefront.default_storefront? ? recipient.email : order.email}>"
    from = "#{order.storefront.name} <#{order.storefront.support_email}>"
    subject = "Your #{order.storefront.name} Order (##{order.number})"
    @message = MacroMessage.find_by!(key: :payment_link).build_message(message_params)

    mail(to: to,
         from: from,
         subject: subject) do |format|
      format.html { render layout: 'email_ink' }
    end
  rescue StandardError => e
    Rails.logger.error("Could not send the payment link email to the customer. Error: #{e.message}")
  end

  def expire_at_in_days(expire_at)
    (expire_at.to_date - Time.now.utc.to_date).to_i
  end
end
