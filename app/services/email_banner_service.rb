class EmailBannerService
  def initialize(email, user)
    @email = email
    @user = user
    @finished_orders = @user.number_of_finished_orders
  end

  def build
    module_content = case @email
                     when :cart_abandonment
                       cart_abandonment_content(buyer_class)
                     when :order_confirmation
                       loyalty_program_content
                     end
    if module_content[:code]
      Coupon.validate_coupon(module_content[:code], module_content[:discount]) ? module_content : nil
    else
      module_content
    end
  end

  def cart_abandonment_content(buyer_class)
    {
      image_url: get_discount_icon(buyer_class),
      code: I18n.t("email_offer_banners.#{@email}.#{buyer_class}.code"),
      discount: I18n.t("email_offer_banners.#{@email}.#{buyer_class}.discount"),
      order: I18n.t("email_offer_banners.#{@email}.#{buyer_class}.order")
    }
  end

  def loyalty_program_content
    points = @user.loyalty_point_balance
    {
      points_earned: (points[:finalized] + points[:pending]) % LoyaltyTransaction::ORDERS_NEEDED_FOR_REWARD,
      points_left: LoyaltyTransaction::ORDERS_NEEDED_FOR_REWARD - ((points[:finalized] + points[:pending]) % LoyaltyTransaction::ORDERS_NEEDED_FOR_REWARD),
      reward_earned?: (LoyaltyTransaction::ORDERS_NEEDED_FOR_REWARD - (@user.loyalty_point_balance[:finalized] + @user.loyalty_point_balance[:pending])).zero?
    }
  end

  private

  def buyer_class
    case @finished_orders
    when 0 then 'non_buyer'
    when 1 then 'one_purchase'
    end
  end

  def get_discount_icon(buyer_class)
    if buyer_class == 'non_buyer'
      ActionController::Base.helpers.asset_url('email/cart_abandonment/sticker10.png')
    else
      ActionController::Base.helpers.asset_url('email/cart_abandonment/sticker5.png')
    end
  end
end
