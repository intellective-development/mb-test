# == Schema Information
#
# Table name: bulk_orders
#
#  id                   :integer          not null, primary key
#  storefront_id        :integer
#  order_count          :integer
#  graphic_engraving    :boolean
#  delivery_method      :integer
#  csv                  :text
#  placed_at            :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  status               :integer          default("active")
#  billing_email        :string           default(""), not null
#  billing_company      :string
#  billing_address      :string           default(""), not null
#  billing_address_info :string
#  billing_city         :string           default(""), not null
#  billing_state        :string           default(""), not null
#  billing_zip          :string           default(""), not null
#  billing_phone        :string           default(""), not null
#  storefront_quote_id  :integer          default(0), not null
#  coupon_id            :integer
#  logo_file_name       :string
#  logo_content_type    :string
#  logo_file_size       :bigint(8)
#  logo_updated_at      :datetime
#  line1                :string
#  line2                :string
#  line3                :string
#  line4                :string
#  billing_first_name   :string
#  billing_last_name    :string
#  name                 :string
#  supplier_ids         :integer          default([]), is an Array
#
# Indexes
#
#  index_bulk_orders_on_coupon_id  (coupon_id)
#
# Foreign Keys
#
#  fk_rails_...  (coupon_id => coupons.id)
#
class BulkOrder < ActiveRecord::Base
  belongs_to :coupon
  belongs_to :storefront
  belongs_to :storefront_quote, class_name: 'Storefront'
  belongs_to :supplier, optional: true

  has_many :bulk_order_orders
  has_many :orders, through: :bulk_order_orders
  has_many :carts, through: :bulk_order_orders

  validates :storefront, :storefront_quote, :name, presence: true
  validates :delivery_method, presence: true

  # save state of order data changes
  before_save :set_order_data_changed

  # process order data only after save, this means different data
  # has been saved and new orders need to happen
  after_save :reindex
  after_save :process_order_data, if: :order_data_changed?

  has_attached_file :logo, BASIC_PAPERCLIP_OPTIONS.merge(path: 'bulk_orders/:id/:style/:basename.:extension')
  validates_attachment_content_type :logo, content_type: ['image/jpg', 'image/jpeg', 'image/png', 'image/gif', 'image/x-eps', 'application/postscript']

  enum status: { active: 0, canceled: 1, in_progress: 2, finalizing: 3, finalized: 4 }
  enum delivery_method: { shipped: 0, pickup: 1, on_demand: 2, digital: 3 }

  #-----------------------------------
  # SearchKick
  #-----------------------------------
  searchkick index_name: -> { "#{name.tableize}_#{ENV['SEARCHKICK_SUFFIX'] || ENV['RAILS_ENV']}" },
             word_end: [:number],
             batch_size: 200,
             searchable: %w[name storefront_id created_at]

  def search_data
    {
      name: humanized_name.downcase,
      storefront: storefront_id,
      created_at: created_at.to_time
    }
  end

  def humanized_name
    name.present? ? "#{name} (#{id})" : id.to_s
  end

  def order_data_changed?
    @order_data_changed
  end

  def bulk_order_taxed_total
    bulk_order_orders.map(&:invoice_total).sum
  end

  def order_items_summary
    products = {}

    bulk_order_orders.each do |bulk_order|
      bulk_order.order.order_items.joins(:product).each do |oi|
        product_name = oi.variant.product.name
        product_id = oi.variant.product.id

        products[product_id] = {
          name: product_name,
          quantity: oi.quantity + (products[product_id] ? products[product_id][:quantity] : 0),
          amounts: {
            subtotal: bulk_order.invoice_subtotal + (products[product_id] ? products[product_id][:amounts][:subtotal] : 0),
            delivery: bulk_order.invoice_delivery + (products[product_id] ? products[product_id][:amounts][:delivery] : 0),
            taxes: bulk_order.invoice_taxes + (products[product_id] ? products[product_id][:amounts][:taxes] : 0),
            service_fee: bulk_order.invoice_service_fee + (products[product_id] ? products[product_id][:amounts][:service_fee] : 0),
            tip_amount: bulk_order.invoice_tip_amount + (products[product_id] ? products[product_id][:amounts][:tip_amount] : 0),
            total: bulk_order.invoice_total + (products[product_id] ? products[product_id][:amounts][:total] : 0)
          }
        }
      end
    end

    products
  end

  def process_order_data
    BulkOrder::CreateOrdersWorker.perform_async(id)
  end

  def supplier_names
    Supplier.where(id: supplier_ids).pluck(:name).join(', ')
  end

  private

  def set_order_data_changed
    @order_data_changed = csv_changed?
    true # otherwise it will break callback chain
  end
end
