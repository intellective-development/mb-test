# == Schema Information
#
# Table name: order_items
#
#  id                :integer          not null, primary key
#  price             :decimal(8, 2)
#  total             :decimal(8, 2)
#  variant_id        :integer          not null
#  tax_rate_id       :integer
#  shipment_id       :integer
#  created_at        :datetime
#  updated_at        :datetime
#  quantity          :integer          default(1)
#  sale_item         :boolean          default(FALSE), not null
#  tax_address_id    :integer
#  tax_charge        :decimal(8, 2)
#  substitute_id     :integer
#  item_options_id   :integer
#  bottle_deposits   :decimal(8, 2)    default(0.0)
#  identifier        :decimal(, )      not null
#  product_bundle_id :string
#
# Indexes
#
#  index_order_items_on_created_at                  (created_at)
#  index_order_items_on_item_options_id             (item_options_id)
#  index_order_items_on_product_bundle_id           (product_bundle_id)
#  index_order_items_on_shipment_id                 (shipment_id)
#  index_order_items_on_shipment_id_and_identifier  (shipment_id,identifier)
#  index_order_items_on_variant_id                  (variant_id)
#

class OrderItem < ApplicationRecord
  include OrderItem::SegmentSerializer
  include Iterable::Storefront::Serializers::OrderItemSerializer

  attr_accessor :item_id # used on internal checkout endpoint

  belongs_to :shipment, inverse_of: :order_items
  belongs_to :tax_address, class_name: 'Address'
  belongs_to :tax_rate # obsolete
  belongs_to :variant, inverse_of: :order_items
  belongs_to :item_options
  belongs_to :product_bundle, optional: true

  has_one :product_size_grouping, through: :variant
  has_one :brand, through: :product_size_grouping
  has_one :product, through: :variant
  has_one :hierarchy_category, through: :product
  has_one :inventory, through: :variant
  has_one :order, through: :shipment
  has_one :product_type, through: :product
  has_one :ship_address, through: :order
  has_one :shipping_method, through: :shipment
  has_one :supplier, through: :variant
  has_one :substitution, foreign_key: 'original_id'

  has_many :coupons

  validates :quantity, numericality: { only_integer: true, greater_than: 0, less_than: 999 }
  validates :shipment, presence: true, unless: :skip_shipment_validation?
  validates :variant, presence: true

  delegate :address, to: :supplier, allow_nil: true, prefix: true
  delegate :admin_item_volume, to: :product, allow_nil: true, prefix: true
  delegate :case_eligible?, to: :variant, allow_nil: true
  delegate :two_for_one, to: :variant, allow_nil: true
  delegate :gift_card?, to: :variant, allow_nil: true
  delegate :id, to: :product, allow_nil: true, prefix: true
  delegate :name, to: :brand, allow_nil: true, prefix: true
  delegate :id, to: :brand, allow_nil: true, prefix: true
  delegate :name, to: :product_type_root, allow_nil: true, prefix: true
  delegate :name, to: :product, allow_nil: true, prefix: true
  delegate :product_trait_name, to: :product, allow_nil: true
  delegate :product_grouping_id, to: :product, allow_nil: true
  delegate :root, to: :product_type, allow_nil: true, prefix: true
  delegate :sku, to: :variant, allow_nil: true, prefix: true
  delegate :supplier_id, to: :variant, allow_nil: true
  delegate :tag_list, to: :product_size_grouping, allow_nil: true, prefix: 'product_grouping'
  delegate :tax_category_id, to: :product, allow_nil: true
  delegate :type_hierarchy, to: :product, allow_nil: true, prefix: true
  delegate :upc, to: :product, allow_nil: true, prefix: true

  before_create do
    set_price_from_variant unless price?
    set_identifier
    set_sale_item
  end

  before_save :recalculate_tax_and_fees, if: :should_recalculate_tax?
  before_save :calculate_total
  accepts_nested_attributes_for :item_options
  accepts_nested_attributes_for :coupons

  #----------------------------------------
  # Scopes
  #----------------------------------------
  scope :gift_card, -> { joins(:variant).merge(Variant.gift_card) }
  scope :engraving, -> { joins(:item_options).where.not(item_options: { line1: nil }) }

  #----------------------------------------
  # Instance methods
  #----------------------------------------
  # This feels like a hack, but it gives some backward compatibility to
  # orders without a quantity. This could go after a migrate script to
  # populate the default(1) for all nil quantities.
  def quantity
    super || self.quantity = 1
  end

  def price
    if item_options&.price? && variant.overridable?
      item_options.price
    else
      attributes['price'] || set_price_from_variant
    end
  end

  def update_inventory
    inventory.reduce_by(quantity)
  end

  def total
    super || calculate_total
  end

  def engraving?
    !item_options&.line1.nil? || !item_options&.graphic_engraving_image.nil?
  end

  def engraving_fee
    return 0.0 unless engraving?

    (quantity * order.storefront.engraving_fee).to_f.round(2)
  end

  def tax_address
    attributes['tax_address'] || set_tax_address
  end

  # deprecated
  def tax_rate
    Kernel.warn 'order_item.tax_rate is deprecated and should not be longer used.'

    attributes['tax_rate'] || set_tax_rate
  end

  def effective_tax_percentage
    return attributes['tax_rate']&.percentage if attributes['tax_rate']

    ((tax_charge * 100) / total).to_f.round(2)
  end

  def tax_charge_with_bottle_deposits
    (tax_charge + bottle_fee).to_f.round(2)
  end

  def tax_charge(allow_recalculation = false)
    attributes['tax_charge'] || (allow_recalculation && recalculate_tax_and_fees) || 0.0
  end

  def bottle_fee(allow_recalculation = false)
    attributes['bottle_deposits'] || (allow_recalculation && recalculate_tax_and_fees) || 0.0
  end

  alias bottle_deposits bottle_fee

  def alcohol?
    product&.product_type&.is_alcohol?
  end

  def recipients
    item_options.present? ? item_options.recipients : []
  end

  def send_date
    item_options&.send_date
  end

  def description
    format('%<quantity>s %<variant_name>s at %<price>s for a total %<total>s.',
           { quantity: quantity, variant_name: variant.name, price: ntc(price), total: ntc(price * quantity) })
  end

  def recalculate_and_apply_taxes
    return if self.shipment.nil? || self.shipment.liquid_shipment?

    tax_calculation = shipment.calculate_taxes
    # For non-liquid shipments, always set tax_charge from tax_calculation
    self.tax_charge = tax_calculation.get_tax_for_item(self)

    if seven_eleven_bottle_deposits
      self.bottle_deposits = seven_eleven_bottle_deposits
    else
      # Bottle deposits were resetting each time prior to saving
      unless bottle_deposits_changed?
        self.bottle_deposits = tax_calculation.get_bottle_fee_for_item(self)
      end
    end
  rescue StandardError => e
    trace = (["#{self.class} - #{e.class}: #{e.message}"] + e.backtrace).join("\n")
    msg = "Cannot recalculate_and_apply_taxes for order_item: #{id}, trace: #{trace}"
    notify_sentry_and_log(e, msg, { tags: { order_item: id || 0 } })
  end

  def seven_eleven_bottle_deposits
    return bottle_deposits if Feature[:seven_eleven_bag_fee].enabled? && supplier.dashboard_type == Supplier::DashboardType::SEVEN_ELEVEN

    nil
  end

  def in_pre_sale?
    PreSale.active.find_by(product_id: product_id).present?
  end

  def discounts_total_value
    # deals_amount + coupon_share + shop runner_amount
    ValueSplitter
      .new(shipment.discounts_total_share, limit: shipment.discounts_total_share)
      .split(shipment.sub_total, total).to_f.round_at(2) +
      # free_product_discount
      (shipment.cached_free_product_item == self ? shipment.cached_free_product_item.price : 0.0)
  end

  protected

  def ntc(amount)
    ActiveSupport::NumberHelper.number_to_currency(amount, precision: 2)
  end

  def skip_shipment_validation?
    false
  end

  def shipment?
    self[:shipment_id].present?
  end

  def should_recalculate_tax?
    (price_changed? || quantity_changed?)
  end

  def set_identifier
    self.identifier = variant.id unless identifier.present?
  end

  def set_price_from_variant
    self.price = variant.price if variant.price > 0.01
  end

  def set_sale_item
    self.sale_item = variant.on_sale?
    true
  end

  def calculate_total
    self.total = (quantity.to_f * price.to_f).round_at(2)
  end

  def discounts_total
    return 0.0 unless shipment?

    restrictions = Deals::LegalRestrictions.new(order&.ship_address&.state_abbr_name || order&.promo_address&.fetch('state'))
    value_calculator = Deals::ValueCalculator.new(restrictions, order_items: order&.order_items)
    applied_deal_ids = shipment.applied_deals.pluck(:deal_id)

    Deal.where(id: applied_deal_ids)
        .map { |deal| value_calculator.call_for_item(self, deal) }.inject(:+) || 0.0
  end

  def recalculate_tax_and_fees
    cached_amount = @association_cache[:shipment]&.target
    return if cached_amount.liquid
    recalculate_and_apply_taxes unless Feature[:skip_order_tax_calculation_feature].enabled?
  end

  # deprecated
  def set_tax_rate
    return if tax_address.nil?

    self.tax_rate = TaxRate.lookup(tax_address.zip_code, tax_address.probable_state_id, tax_category_id)
  end

  def set_tax_address
    self.tax_address = shipment&.pickup? ? supplier_address : order&.ship_address
  end
end
