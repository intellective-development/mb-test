class OrderAdjustmentCreationService
  attr_accessor :shipment, :order, :params, :amount, :records, :errors, :error_record, :business_adjustment

  delegate :covered_by_coupon?, to: :order, prefix: true

  def initialize(shipment, params, business_adjustment = false)
    @shipment = shipment
    @order = shipment&.order
    @params = params
    @business_adjustment = business_adjustment
    @amount = @params[:amount].to_f
    @records = []
    @error_record = nil
  end

  def financial?
    params[:financial].to_s == 'true'
  end

  def credit?
    params[:credit].to_s == 'true'
  end

  def order_has_coupon?
    order.coupon.present? || !order.coupons.empty?
  end

  def order_paid_with_credit_card?
    !order_has_coupon? || (!order.coupon.is_a?(CouponDecreasingBalance) && order.coupons.empty?)
  end

  def order_has_charges?
    order.charges.any?
  end

  def order_coupon_amount
    order.coupon_amount.to_f
  end

  def order_credit_card_balance
    shipment.charges.sum(&:balance)
  end

  def order_coupon_balance
    coupons = order.all_gift_card_coupons
    coupon_balance = 0
    coupon_balance = coupons.sum(&:balance) if coupons.present?
    coupon_balance
  end

  def process_now!
    records.each(&:process) if process!
  end

  def process!
    if order_paid_with_credit_card?
      create_credit_card_adjustment!
    elsif credit?
      process_refund!
    else
      process_charge!
    end
    if records.all?(&:valid?)
      records.map(&:save)
      true
    else
      @error_record = records.find { |record| !record.valid? }
      @error_record.assign_attributes(amount: amount) # so in validation form we dont overwrite amount
      @errors = @error_record.errors.full_messages
      false
    end
  end

  def process_refund!
    if order_has_charges? && order_coupon_amount.zero?
      create_credit_card_adjustment!
    elsif order_covered_by_coupon? && !order_has_charges?
      create_coupon_adjustment!
    else
      amount_to_refund = amount
      if amount_to_refund > order_credit_card_balance
        if order_credit_card_balance.positive?
          amount_to_refund -= order_credit_card_balance
          create_credit_card_adjustment!(order_credit_card_balance)
        end
        create_coupon_adjustment!(amount_to_refund)
      else
        create_credit_card_adjustment!(amount_to_refund)
      end
    end
  end

  def process_charge!
    amount_to_charge = amount
    if order_coupon_balance >= amount_to_charge
      create_coupon_adjustment!
    else
      amount_to_charge = amount
      if order_coupon_balance.positive?
        amount_to_charge -= order_coupon_balance
        create_coupon_adjustment!(order_coupon_balance)
      end
      create_credit_card_adjustment!(amount_to_charge)
    end
  end

  def create_coupon_adjustment!(adjustment_amount = amount)
    @records << shipment.order_adjustments.new(params.merge(adjustment_type: 'coupon', amount: adjustment_amount))
  end

  def create_credit_card_adjustment!(adjustment_amount = amount)
    adjustment_params = params.merge(adjustment_type: 'credit_card', amount: adjustment_amount)

    if @business_adjustment
      business_adjustment_params = adjustment_params.merge(taxes: true, supplier_id: @shipment.order.storefront.business.fee_supplier.id)
      @records << shipment.order_adjustments.new(business_adjustment_params)
    else
      @records << shipment.order_adjustments.new(adjustment_params)
    end
  end
end
