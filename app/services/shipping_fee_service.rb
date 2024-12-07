class ShippingFeeService
  attr_reader :shipping_fee, :shipping_discount, :delivery_discount, :fulfillment_fee,
              :membership_shipping_discount, :membership_delivery_discount

  def initialize(shipment)
    @shipment = shipment
    @order = shipment.order
    @storefront = @order.storefront

    @shipping_method = @shipment.shipping_method || @shipment.supplier.default_shipping_method
    @minimum = @shipping_method&.delivery_minimum
    @free_threshold = @shipping_method&.delivery_threshold
    @fee = @shipping_method&.delivery_fee.to_f
    @sub_total = @shipment.sub_total

    # Only one of 3 variables are bigger than 0
    @shipping_fee = 0.0
    @shipping_discount = 0.0
    @delivery_discount = 0.0
    @fulfillment_fee = 0.0
    @membership_shipping_discount = 0.0
    @membership_delivery_discount = 0.0
    calculate_fee_and_reimbursement! if @shipment.item_count != 0
  end

  def always_free_delivery?
    @fee.zero? || (@free_threshold.present? && @free_threshold <= @minimum)
  end

  def never_free_delivery?
    @free_threshold.blank? && !@fee.zero?
  end

  def below_free_threshold?
    @sub_total < @free_threshold
  end

  def incremental_shipping_fee
    fee = @fee
    extra_qty = @shipment.item_count - 1
    fee += (extra_qty / 12).floor * 30
    fee += (extra_qty % 12) != 0 ? 10 : 0
    fee.to_f.round_at(2)
  end

  def potential_membership_shipping_savings(membership_plan)
    membership_shipping_discount?(membership_plan) ? @shipping_fee : 0.0
  end

  def potential_membership_on_demand_savings(membership_plan)
    membership_on_demand_discount?(membership_plan) ? @shipping_fee : 0.0
  end

  private

  def shipment_index
    # Shipment index in order sorted by id, see https://minibar.atlassian.net/browse/RBRP-4?focusedCommentId=44564
    @shipment_index ||=
      begin
        # @order.shipments.preload(:shipping_method) will do 2 new requests
        ActiveRecord::Associations::Preloader.new.preload(@order.shipments, :shipping_method)
        @order.shipments
              .select { |s| s.shipping_method.shipping_type == @shipping_method.shipping_type }
              .sort_by { |s| [Shipment.customer_placements[s.customer_placement], s.id] }
              .map(&:id)
              .index(@shipment.id)
      end
  end

  # For the 'first' fee mode we should only charge shipping fee to first shipment of given shipping_type in order,
  # all others should be free (but we'll do a reimbrusement to suppliers later)
  # For shipments on 'shipped' method we use flat single_shipping_fee defined in storefront
  # For shipment on 'on_demand' method we use same logic as in :all mode
  # We have separate fields for shipping_discount and delivery_discount for the sake of reporting only
  def calculate_fee_for_mode_first
    if @shipping_method.on_demand?
      fee = calculate_fee_for_mode_all
      if shipment_index.zero?
        if Feature[:enable_rb_can_cover_shipping_fee].enabled? && @storefront.shipping_fee_covered_by_rb?
          @delivery_discount = fee
        else
          @shipping_fee = fee
        end
      else
        @delivery_discount = fee
      end
    elsif @shipping_method.shipped?
      fee = @storefront.single_shipping_fee
      fee = 15.95 if Feature[:enable_pre_sale_shipping_fee].enabled? && @shipment.customer_placement_pre_sale?

      if shipment_index.zero?
        if Feature[:enable_rb_can_cover_shipping_fee].enabled? && @storefront.shipping_fee_covered_by_rb?
          @shipping_discount = fee
        else
          @shipping_fee = fee
        end
      else
        @shipping_discount = fee
      end
    else
      # 'first' mode should only be applied for Reservebar, and it should only works with two shipping types above
      # But if by some strange reason we will find ourselves here, we fallback to standard Minibar calculation logic
      @shipping_fee = calculate_fee_for_mode_all
    end
  end

  # Standard 'Minibar'-style shipping fee
  def calculate_fee_for_mode_all
    # all fields are already set to 0 in initialize
    return 0 if always_free_delivery? || (!never_free_delivery? && !below_free_threshold?)

    incremental = @shipping_method&.shipped? && !@shipping_method&.shipping_flat_fee
    incremental ? incremental_shipping_fee : @fee
  end

  def calculate_dynamic_fee
    DynamicShippingService.new(@shipment).shipping_fee
  end

  def calculate_fee_and_reimbursement!
    if @storefront.enable_dynamic_shipping?
      @shipping_fee = @shipment.shipped? ? calculate_dynamic_fee : calculate_fee_for_mode_all
    elsif @storefront.supplier_fee_mode_first?
      calculate_fee_for_mode_first
    elsif @storefront.supplier_fee_mode_all?
      @shipping_fee = calculate_fee_for_mode_all
    else
      # Should never happen
      raise "Unexpected supplier_fee_mode: #{@storefront.supplier_fee_mode}"
    end
    @fulfillment_fee = @shipping_fee

    apply_membership_discount!
  end

  def apply_membership_discount!
    if membership_on_demand_discount?
      @membership_delivery_discount = @shipping_fee
      @delivery_discount = [@shipping_fee, @delivery_discount].max
      @shipping_fee = 0.0
    elsif membership_shipping_discount?
      @membership_shipping_discount = @shipping_fee
      @shipping_discount = [@shipping_fee, @shipping_discount].max
      @shipping_fee = 0.0
    end
  end

  def membership_shipping_discount?(membership_plan = nil)
    membership_plan ||= @order.membership_plan_record
    @shipping_method.shipped? && membership_plan&.free_shipping?(@order.sub_total)
  end

  def membership_on_demand_discount?(membership_plan = nil)
    membership_plan ||= @order.membership_plan_record
    @shipping_method.on_demand? && membership_plan&.free_on_demand?(@order.sub_total)
  end
end
