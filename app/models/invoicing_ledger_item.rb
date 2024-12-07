# == Schema Information
#
# Table name: invoicing_ledger_items
#
#  id                           :integer          not null, primary key
#  sender_id                    :integer
#  recipient_id                 :integer
#  type                         :string(255)
#  issue_date                   :datetime
#  currency                     :string(3)        not null
#  total_amount                 :decimal(20, 4)
#  tax_amount                   :decimal(20, 4)
#  status                       :string(20)
#  identifier                   :string(50)
#  description                  :string(255)
#  period_start                 :datetime
#  period_end                   :datetime
#  uuid                         :string(40)
#  due_date                     :datetime
#  created_at                   :datetime
#  updated_at                   :datetime
#  minibar_percent              :decimal(, )
#  business_id                  :integer          default(1)
#  sub_total                    :decimal(, )
#  taxed_amount                 :decimal(, )
#  tip_amount                   :decimal(, )
#  shipping_charges             :decimal(, )
#  items_total_amount           :decimal(, )
#  supplier_funded_discounts    :decimal(, )
#  minibar_funded_discounts     :decimal(, )
#  net_amount                   :decimal(, )
#  bottle_deposits              :decimal(, )
#  promo_codes_discount         :decimal(, )
#  shipping_reimbursement_total :decimal(, )
#  gift_card_amount             :decimal(, )
#  paypal_funds                 :decimal(, )
#  marketing_fee                :decimal(, )
#  invoiced_shipments           :integer
#
# Indexes
#
#  index_invoicing_ledger_items_on_id_and_type   (id,type)
#  index_invoicing_ledger_items_on_recipient_id  (recipient_id)
#  index_invoicing_ledger_items_on_uuid          (uuid)
#

class InvoicingLedgerItem < ActiveRecord::Base
  ### statuses
  # pending: starting point
  # moves to
  #   finalized: invoice is now immutable. order adjustments have been added. invoice was sent
  #   voided: invoice was wrong and needs to be recalculated

  acts_as_ledger_item

  has_many :line_items, class_name: 'InvoicingLineItem', foreign_key: :ledger_item_id
  has_many :booze_carriage_orders, class_name: 'BoozeCarriageOrder', foreign_key: :ledger_item_id
  has_many :refunds, class_name: 'Refund', foreign_key: :ledger_item_id
  has_many :customer_orders, class_name: 'CustomerOrder', foreign_key: :ledger_item_id
  has_many :additional_charges, class_name: 'AdditionalCharge', foreign_key: :ledger_item_id
  has_many :flat_fees, class_name: 'FlatFee', foreign_key: :ledger_item_id
  has_many :gateway_fees, class_name: 'GatewayFee', foreign_key: :ledger_item_id

  belongs_to :recipient, class_name: 'InvoicingRecipient'
  belongs_to :business

  validates :recipient_id, presence: true
  validates :type, presence: true
  validates :uuid, uniqueness: true

  scope :by_business, ->(business_id) { where(business_id: business_id) }
  scope :finalized, -> { where(status: 'finalized') }

  state_machine :status, initial: 'new' do
    state 'new'
    state 'pending'
    state 'built'
    state 'finalized'
    state 'voided'
    state 'paid'

    before_transition 'new' => 'pending', do: [:set_init_fields]
    before_transition 'pending' => 'built', do: [:build_line_items]
    before_transition 'built' => 'finalized', do: %i[add_braintree_gateway_charge set_finalized_data]
    before_transition any => 'voided', do: [:detach_line_items]

    event :begin do
      transition to: 'pending', from: 'new'
    end

    event :build do
      transition to: 'built', from: 'pending'
    end

    event :finalize do
      transition to: 'finalized', from: 'built'
    end

    event :pay do
      transition to: 'paid', from: 'finalized'
    end

    event :void do
      transition to: 'voided', except_from: %w[voided paid]
    end
  end

  def recipient_name
    recipient.description
  end

  def period_name
    period_start.utc.strftime('%B %Y')
  end

  def find_shipments_for_invoice
    @find_shipments_for_invoice ||= recipient.supplier.get_invoice_shipments(business_id, period_start, period_end)
  end

  def find_pending_adjustments
    @find_pending_adjustments ||= OrderAdjustment.includes([:reason, { order: :storefront }])
                                                 .joins(:reason, shipment: [order: :storefront])
                                                 .where(storefronts: { business_id: business.id })
                                                 .where(
                                                   shipments: { supplier_id: get_supplier_ids },
                                                   created_at: period_start...period_end,
                                                   line_item_id: nil
                                                 ).where.not(amount: 0)
  end

  def adjustments_for_marketing_fee
    @adjustments_for_marketing_fee ||= OrderAdjustment.includes([:reason, { order: :storefront }])
                                                      .joins(:reason, shipment: [order: :storefront])
                                                      .where(storefronts: { business_id: business.id })
                                                      .where(order_adjustment_reasons: { marketing_fee_adjustment: true })
                                                      .where(taxes: false)
                                                      .where(
                                                        shipments: { supplier_id: get_supplier_ids },
                                                        created_at: period_start...period_end,
                                                        line_item_id: nil
                                                      ).where.not(amount: 0)
  end

  def canceled_shipments_for_adjustments
    @canceled_shipments_for_adjustments ||= Shipment.canceled
                                                    .includes(:shipment_amount, order: :storefront)
                                                    .where(
                                                      supplier_id: get_supplier_ids,
                                                      canceled_at: period_start...period_end,
                                                      order: { storefronts: { business_id: business_id } },
                                                      shipment_amounts: { line_item_cancellation_id: nil }
                                                    ).where.not(shipment_amounts: { line_item_id: nil })
  end

  def add_adjustment_line(order_adjustment)
    return unless order_adjustment.line_item_id.nil?

    reason = order_adjustment.reason

    line_item_type = generate_line_item_type(order_adjustment, reason)

    line_item_amount = line_item_type == 'Refund' ? -order_adjustment.amount : order_adjustment.amount
    marketing_fee = reason.marketing_fee_adjustment ? line_item_amount * minibar_percent : 0

    order = order_adjustment.order
    line_item = line_items.create!(
      description: "#{order.number}_#{order_adjustment.id}",
      type: line_item_type,
      tax_point: order.created_at,
      order_number: order.number,
      minibar_funded_discounts: minibar_funded_discounts.presence,
      marketing_fee: marketing_fee,
      net_amount: marketing_fee + line_item_amount
    )
    order_adjustment.update_attribute(:line_item_id, line_item.id)
  end

  def add_marketing_fee_from_order_adjustment(order_adjustment)
    order = order_adjustment.order
    amount = order_adjustment.credit? ? -order_adjustment.amount : order_adjustment.amount
    marketing_fee = amount * minibar_percent
    line_item = line_items.create!(
      description: "#{order.number}_#{order_adjustment.id}",
      type: order_adjustment.credit? ? 'AdditionalCharge' : 'Refund',
      tax_point: order.created_at,
      order_number: order.number,
      marketing_fee: marketing_fee,
      net_amount: marketing_fee
    )
    order_adjustment.update_attribute(:line_item_id, line_item.id)
  end

  def rerun
    detach_line_items
    line_items.destroy_all
    build_line_items
    set_finalized_data
  end

  def add_marketing_fee_from_order_adjustments(tier)
    return unless tier.percent?

    adjustments_for_marketing_fee.each do |adjustment|
      next unless include_adjustment_line?(adjustment)

      add_marketing_fee_from_order_adjustment(adjustment)
    end
  end

  def add_adjustments_from_cancelled_shipments(tier)
    return unless tier.flat? || tier.percent?

    canceled_shipments_for_adjustments.each do |shipment|
      add_adjustment_from_canceled_shipment(shipment, tier)
    end
  end

  private

  def generate_line_item_type(order_adjustment, reason)
    return 'Refund' if reason.owed_to_supplier || substitution_higher_value_covered_by_business?(order_adjustment, reason)
    return 'AdditionalCharge' if reason.owed_to_minibar

    order_adjustment.credit? ? 'AdditionalCharge' : 'Refund'
  end

  # Checks if a order adjustment is a higher value substitution and if it is covered by the business
  # In this cases we want to add a refund line item instead of an additional charge
  def substitution_higher_value_covered_by_business?(order_adjustment, reason)
    !reason.owed_to_minibar && !reason.owed_to_supplier && !order_adjustment.credit && !order_adjustment.financial
  end

  def set_init_fields
    update(
      status: 'pending',
      description: recipient.email,
      uuid: SecureRandom.uuid,
      minibar_percent: 0
    )
  end

  def set_finalized_data
    values = get_line_items_values

    update(
      status: 'finalized',
      due_date: 15.days.since,
      issue_date: Time.zone.now,
      sub_total: values[:sub_total],
      taxed_amount: values[:taxed_amount],
      tip_amount: values[:tip_amount],
      bottle_deposits: values[:bottle_deposits],
      promo_codes_discount: values[:promo_codes_discount],
      shipping_reimbursement_total: values[:shipping_reimbursement_total],
      gift_card_amount: values[:gift_card_amount],
      paypal_funds: values[:paypal_funds],
      marketing_fee: values[:marketing_fee],
      shipping_charges: values[:shipping_charges],
      items_total_amount: values[:items_total_amount],
      supplier_funded_discounts: values[:supplier_funded_discounts],
      minibar_funded_discounts: values[:minibar_funded_discounts],
      net_amount: values[:net_amount],
      invoiced_shipments: values[:invoiced_shipments]
    )
  end

  def get_supplier_ids
    delegatees = Supplier.where(delegate_invoice_supplier_id: recipient.supplier.id).pluck(:id)
    delegatees << recipient.supplier.id
    delegatees
  end

  def find_net(shipments)
    sub_total = 0.0
    discounts = 0.0

    total = shipments.count
    row = 0
    shipments.each do |shipment|
      Rails.logger.warn "Processing shipment #{row += 1}/#{total}"
      next unless shipment.order

      amount = shipment.shipment_amount
      sub_total += amount.sub_total
      discounts += amount.minibar_funded_discounts
    end

    sub_total - discounts
  end

  def find_tier(shipments)
    flat_order_tier = InvoiceTier.by_business(business_id)
                                 .active_at(period_start)
                                 .where(tier_type: 'flat_order')
                                 .for_supplier(supplier_id)
                                 .first
    return flat_order_tier if flat_order_tier

    # work through a collection of shipments to find the right invoicing bracket
    total_for_invoice = find_net(shipments)

    InvoiceTier.by_business(business_id)
               .active_at(period_start)
               .with_sum(total_for_invoice)
               .for_supplier(supplier_id)
               .first
  end

  def add_adjustment_from_canceled_shipment(shipment, _tier)
    order = shipment.order

    previous_line_item = shipment.shipment_amount.line_item
    marketing_fee = previous_line_item&.marketing_fee || 0
    net_amount = previous_line_item&.net_amount || 0
    paypal_funds = previous_line_item&.paypal_funds.present? ? previous_line_item.paypal_funds * -1 : nil

    return if net_amount.zero? && marketing_fee.zero?

    line_item = line_items.create!(
      description: "#{order.number}_#{shipment.id}",
      type: 'OrderCancellation',
      tax_point: order.created_at,
      order_number: order.number,
      marketing_fee: -1 * marketing_fee,
      net_amount: -1 * net_amount,
      paypal_funds: paypal_funds
    )
    shipment.shipment_amount.update_attribute(:line_item_cancellation_id, line_item.id)
  end

  def build_line_item(record, line_item_type, net_amount, append = '', shipment_amount = nil)
    # record is either Shipment or OrderAdjustment, and returns the line item built.
    # for uniqueness, use either the shipment number or the order number with the adjustment id
    order_number = record.order.number
    description = order_number
    description += append
    paypal = shipment_amount&.shipment&.order&.payment_profile&.paypal? || false
    paypal_funds = paypal ? shipment_amount&.shipment&.total_supplier_charge : 0
    marketing_fee = (shipment_amount&.shipment&.invoicing_sub_total || 0) * minibar_percent

    line_items.create!(
      description: description,
      order_number: order_number,
      type: line_item_type,
      tax_point: record.order.created_at,
      sub_total: shipment_amount&.shipment&.invoicing_sub_total,
      taxed_amount: shipment_amount&.taxes_due_minibar,
      bottle_deposits: shipment_amount&.fees_due_retailer,
      tip_amount: shipment_amount&.tip_amount,
      shipping_charges: shipment_amount&.shipping_charges,
      total_amount: shipment_amount&.shipment&.total_before_gift_cards,
      supplier_funded_discounts: shipment_amount&.supplier_funded_discounts,
      minibar_funded_discounts: shipment_amount&.minibar_funded_discounts,
      net_amount: net_amount,
      tax_amount: 0,
      promo_codes_discount: shipment_amount&.promo_codes_discount,
      shipping_reimbursement_total: shipment_amount&.shipping_reimbursement_total,
      gift_card_amount: shipment_amount&.gift_card_amount,
      paypal_funds: paypal_funds,
      marketing_fee: marketing_fee
    )
  end

  def build_line_items
    shipments = find_shipments_for_invoice
    Rails.logger.info "Found #{shipments.count} shipments for invoice"
    tier = find_tier(shipments)
    Rails.logger.warn "Found tier: #{tier.inspect}"
    return unless tier

    # avoid empty invoices
    has_no_items = shipments.empty? && find_pending_adjustments.empty? && adjustments_for_marketing_fee.empty? && canceled_shipments_for_adjustments.empty?
    return if has_no_items

    add_minibar_percent(tier) if tier.percent?

    add_shipments(tier, shipments)

    add_business_flat(tier) if (tier.flat? || tier.fixed?) && shipments.any?

    # TECH-3952 - now we are going to automatically add all pending adjustments to the invoice
    add_adjustments!

    add_marketing_fee_from_order_adjustments(tier)
    add_adjustments_from_cancelled_shipments(tier)
  end

  def add_shipments(tier, shipments = [])
    row = 0
    total = shipments.count
    shipments.each do |shipment|
      row += 1
      Rails.logger.warn "Processing shipment for add #{row}/#{total}"
      add_record(shipment, tier)
    end
  end

  def add_adjustments!
    adjustments = find_pending_adjustments
    adjustments.find_in_batches(batch_size: 50) do |batch|
      batch.each do |adjustment|
        next unless include_adjustment_line?(adjustment)

        add_adjustment_line(adjustment)
      end
    end
  end

  def customer_order_on_invoice?(adjustment)
    line_items.any? do |line_item|
      line_item.is_a?(CustomerOrder) && line_item.order_number == adjustment.shipment.order_number
    end
  end

  def customer_order_is_canceled?(adjustment)
    adjustment.shipment&.canceled? || adjustment.order&.canceled?
  end

  def include_adjustment_line?(adjustment)
    return false if customer_order_is_canceled?(adjustment) || adjustment.taxes?

    reason = adjustment.reason

    reason.owed_to_supplier || substitution_higher_value_covered_by_business?(adjustment, reason) ||
      !customer_order_on_invoice?(adjustment)
  end

  def add_record(shipment, tier)
    return unless shipment.shipment_amount.not_invoiced?

    line_item_amount = calculate_item_net_amount(shipment, tier)
    append = "_#{shipment.id}_#{shipment.supplier.name}"
    line_item = build_line_item(shipment, 'CustomerOrder', line_item_amount, append, shipment.shipment_amount)
    shipment.shipment_amount.update_attribute(:line_item_id, line_item.id)
  end

  def calculate_item_net_amount(shipment, tier)
    business_amount(shipment, tier) + taxes_to_charge(shipment.shipment_amount) -
      shipment.shipment_amount.minibar_funded_discounts
  end

  def taxes_to_charge(shipment_amount)
    # We shouldn't charge taxes if we didn't charge it from customer (paid by coupon or GC)
    # Bottle deposits and bag fees are collected by supplier, so they should not be charged
    taxed_amount = shipment_amount.taxed_amount -
                   shipment_amount.bottle_deposits -
                   shipment_amount.bag_fee

    charged = taxed_amount - shipment_amount.total_amount

    charged = charged.positive? ? charged : 0.0

    discounted = charged - shipment_amount.minibar_funded_discounts

    discounted.positive? ? shipment_amount.minibar_funded_discounts : charged
  end

  def business_amount(shipment, tier)
    return shipment.invoicing_sub_total * minibar_percent unless tier.tier_type == 'flat_order'

    InvoiceTier.by_business(business_id)
               .active_at(period_start)
               .with_sum(shipment.invoicing_sub_total)
               .for_supplier(supplier_id)
               .first.tier_value
  end

  def add_minibar_percent(tier)
    update_attribute(:minibar_percent, tier.tier_value / 100)
  end

  def add_business_flat(tier)
    net_amount = tier.tier_value
    line_description = "($#{tier.tier_value})"
    if tier.flat?
      net_amount = transactions * tier.tier_value
      line_description = "($#{tier.tier_value}/transaction)"
    end
    line_items.create(
      description: "#{tier.business_id == Business::RESERVEBAR_ID ? 'ReserveBar' : 'Minibar'} Marketing Fee #{line_description}",
      type: 'FlatFee',
      tax_point: period_end,
      net_amount: net_amount,
      tax_amount: 0
    )
  end

  def add_braintree_gateway_charge
    return unless type == 'SupplierInvoice'
    return if line_items.find_by(description: 'Braintree Gateway Charge ($0.10/transaction)')
    return if transactions.zero?

    line_items.create(
      description: 'Braintree Gateway Charge ($0.10/transaction)',
      type: 'GatewayFee',
      tax_point: period_end,
      net_amount: transactions * 0.1,
      tax_amount: 0
    )
  end

  def detach_line_items
    line_items.includes(%i[ledger_item shipment_amount order_adjustment]).find_each(&:detach)
  end

  def transactions
    line_items.where(type: 'CustomerOrder').count
  end

  def reservebar?
    Business::RESERVEBAR_ID == business_id
  end

  def minibar?
    Business::MINIBAR_ID == business_id
  end

  def get_line_items_values
    values = {
      items_total_amount: 0,
      sub_total: 0,
      taxed_amount: 0,
      bottle_deposits: 0,
      promo_codes_discount: 0,
      shipping_reimbursement_total: 0,
      gift_card_amount: 0,
      paypal_funds: 0,
      marketing_fee: 0,
      tip_amount: 0,
      shipping_charges: 0,
      supplier_funded_discounts: 0,
      minibar_funded_discounts: 0,
      net_amount: 0,
      invoiced_shipments: 0
    }

    line_items.each do |line_item|
      values[:items_total_amount] += (line_item.total_amount || 0) unless InvoicingLineItem::CHARGES_TYPES.include?(line_item.type)
      values[:sub_total] += (line_item.sub_total || 0)
      values[:taxed_amount] += (line_item.taxed_amount || 0)
      values[:bottle_deposits] += (line_item.bottle_deposits || 0)
      values[:promo_codes_discount] += (line_item.promo_codes_discount || 0)
      values[:shipping_reimbursement_total] += (line_item.shipping_reimbursement_total || 0)
      values[:gift_card_amount] += (line_item.gift_card_amount || 0)
      values[:paypal_funds] += (line_item.paypal_funds || 0)
      values[:marketing_fee] += (line_item.marketing_fee || 0)
      values[:tip_amount] += (line_item.tip_amount || 0)
      values[:shipping_charges] += (line_item.shipping_charges || 0)
      values[:supplier_funded_discounts] += (line_item.supplier_funded_discounts || 0)
      values[:minibar_funded_discounts] += (line_item.minibar_funded_discounts || 0)
      values[:net_amount] += (line_item.net_amount || 0)
      values[:invoiced_shipments] += 1 if line_item.type == 'CustomerOrder'
    end
    values
  end

  def supplier_id
    @supplier_id ||= recipient.supplier.delegate_invoice_supplier_id || recipient.supplier.id
  end
end
