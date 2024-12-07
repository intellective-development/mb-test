# == Schema Information
#
# Table name: substitutions
#
#  id                :integer          not null, primary key
#  shipment_id       :integer          not null
#  substitute_id     :integer          not null
#  original_id       :integer          not null
#  status            :integer          default("pending"), not null
#  confirmed_by      :integer
#  confirmed_at      :datetime
#  created_at        :datetime
#  updated_at        :datetime
#  remaining_item_id :integer
#
# Indexes
#
#  index_substitutions_on_created_at         (created_at)
#  index_substitutions_on_original_id        (original_id)
#  index_substitutions_on_remaining_item_id  (remaining_item_id)
#  index_substitutions_on_shipment_id        (shipment_id)
#  index_substitutions_on_substitute_id      (substitute_id)
#
# Foreign Keys
#
#  fk_rails_...  (remaining_item_id => order_items.id)
#

class Substitution < ApplicationRecord
  belongs_to :shipment, touch: true

  belongs_to :substitute, class_name: 'OrderItemTemp' # new one
  belongs_to :remaining_item, class_name: 'OrderItemTemp' # new one with remaining quantity of the original item
  belongs_to :original, class_name: 'OrderItem' # old one

  enum status: {
    cancelled: -1,
    pending: 0,
    approved: 1,
    completed: 2
  }

  def ntc(amount)
    ActiveSupport::NumberHelper.number_to_currency(amount, precision: 2)
  end

  def description
    if remaining_item.present?
      total = (substitute.price * substitute.quantity) + (remaining_item.price * remaining_item.quantity)
      format('%<quantity>s %<variant_name>s at %<original_price>s for a total %<original_total>s with '\
              '%<substitute_quantity>s %<substitute_name>s at %<substitute_price>s and %<remaining_item_quantity>s '\
              '%<remaining_item_name>s at %<remaining_item_price>s for a total %<total>s',
             {
               quantity: original.quantity,
               variant_name: original.variant.name,
               original_price: ntc(original.price),
               original_total: ntc(original.price * original.quantity),
               substitute_quantity: substitute.quantity,
               substitute_name: substitute.variant.name,
               substitute_price: ntc(substitute.price),
               remaining_item_quantity: remaining_item.quantity,
               remaining_item_name: remaining_item.variant.name,
               remaining_item_price: ntc(remaining_item.price),
               total: ntc(total)
             })
    else
      format('%<quantity>s %<variant_name>s at %<original_price>s for a total %<original_total>s with '\
              '%<substitute_quantity>s %<substitute_name>s at %<substitute_price>s for a total %<substitute_total>s',
             {
               quantity: original.quantity,
               variant_name: original.variant.name,
               original_price: ntc(original.price),
               original_total: ntc(original.price * original.quantity),
               substitute_quantity: substitute.quantity,
               substitute_name: substitute.variant.name,
               substitute_price: ntc(substitute.price),
               substitute_total: ntc(substitute.price * substitute.quantity)
             })
    end
  end

  # rubocop:disable Metrics/AbcSize
  def confirm(user_id, onus = false)
    self.confirmed_by = user_id
    self.confirmed_at = Time.zone.now
    approved!

    original_coupon_engraving_fee_discounts = shipment.engraving_fee_discounts_without_membership_discount.to_f
    original_coupon_amount = shipment.coupon_amount.to_f
    original_engraving_fee_discounts = shipment.engraving_fee_discounts.to_f

    shipment.order_items.delete(original)
    substitute_order_item = substitute.becomes(OrderItem)
    shipment.order_items << substitute_order_item

    if remaining_item.present?
      remaining_order_item = remaining_item.becomes(OrderItem)
      shipment.order_items << remaining_order_item
    end

    shipment.reload

    substitute_order_item.recalculate_and_apply_taxes
    remaining_order_item.recalculate_and_apply_taxes if remaining_item.present?

    difference_coupon_engraving_fee_discounts = original_coupon_engraving_fee_discounts - shipment.engraving_fee_discounts_without_membership_discount.to_f
    difference_coupon_amount = original_coupon_amount - shipment.coupon_amount.to_f
    difference_discount_value = difference_coupon_amount - difference_coupon_engraving_fee_discounts

    @difference_supplier = original.total - substitute_order_item.total - difference_discount_value
    @difference_supplier -= remaining_order_item.total if remaining_item.present?

    difference_engraving_fee_discounts = original_engraving_fee_discounts - shipment.engraving_fee_discounts.to_f
    difference_tax_charge = original.tax_charge - substitute_order_item.tax_charge
    difference_bottle_fee = original.bottle_fee - substitute_order_item.bottle_fee

    @difference_minibar = difference_tax_charge + difference_bottle_fee + difference_engraving_fee_discounts
    @difference_minibar = @difference_minibar - remaining_order_item.tax_charge - remaining_order_item.bottle_fee if remaining_item.present?

    @credit_supplier = @difference_supplier.positive?
    @onus_supplier = onus == 'on' && !@credit_supplier
    @financial_supplier = @difference_supplier != 0 && !@onus_supplier
    order_adjustment_params_supplier = { user_id: user_id,
                                         reason: reason(@difference_supplier),
                                         description: format('Description: Substitute %s.', description),
                                         substitution_id: id,
                                         credit: @credit_supplier,
                                         financial: @financial_supplier,
                                         amount: @difference_supplier.abs,
                                         braintree: @financial_supplier,
                                         processed: @onus_supplier }
    create_service_supplier = OrderAdjustmentCreationService.new(shipment, order_adjustment_params_supplier)
    create_service_supplier.process_now!

    if @difference_minibar != 0
      @credit_minibar = @difference_minibar.positive?
      @onus_minibar = onus == 'on' && !@credit_minibar
      @financial_minibar = @difference_minibar != 0 && !@onus_minibar
      order_adjustment_params_minibar = { user_id: user_id,
                                          reason: reason(@difference_minibar),
                                          description: format('Description: Taxes and Fees adjustment for substitution %s.', description),
                                          substitution_id: id,
                                          credit: @credit_minibar,
                                          financial: @financial_minibar,
                                          amount: @difference_minibar.abs,
                                          braintree: @financial_minibar,
                                          processed: @onus_minibar }
      create_service_minibar = OrderAdjustmentCreationService.new(shipment, order_adjustment_params_minibar, true)
      create_service_minibar.process_now!
    end

    substitute_order_item.save!
    remaining_order_item.save! if remaining_item.present?
    shipment.recalculate_order_amounts
    shipment.comments.create({ note: format('Customer accepted substitution (%s). Order adjustment is coming.', description),
                               created_by: user_id,
                               posted_as: :minibar })
    completed!

    shipment.order.reload.bar_os_order_send!(:update_line_items)
    shipment.broadcast_event(:shipment_order_items_changed)
  rescue StandardError => e
    notify_sentry_and_log(e,
                          "Substitution error: #{e.message}",
                          { tags: { substitution_id: id,
                                    shipment_id: shipment&.id,
                                    order_adjustment_id: create_service_supplier&.records&.first&.id,
                                    order_adjustment_minibar_id: create_service_minibar&.records&.first&.id } })
  end
  # rubocop:enable Metrics/AbcSize

  # NOTE: find_by(name: hard-coded-text) is probably not the best way to handle this.
  # Whenever we improve this, also reflect the change in app/views/account/orders/pdf.html.erb.
  def reason(difference)
    if difference.positive?
      OrderAdjustmentReason.find_by(name: 'Item Replacement - Lower Value (only use this OA if you cannot use the sub feature for some reason)')
    elsif difference.negative?
      OrderAdjustmentReason.find_by(name: 'Item Replacement - Higher Value (only use this OA if you cannot use the sub feature for some reason)')
    else
      OrderAdjustmentReason.find_by(name: 'Item Replacement - No Price Difference (only use this OA if you cannot use the sub feature for some reason)')
    end
  end

  def cancel(user_id)
    self.confirmed_by = user_id
    self.confirmed_at = Time.zone.now
    cancelled!

    if original.shipment.present?
      original.shipment.comments.create({
                                          note: format('Customer rejected substitution: %s.', description),
                                          created_by: user_id,
                                          posted_as: :minibar
                                        })
    end

    save
  end
end
