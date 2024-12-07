# == Schema Information
#
# Table name: product_routings
#
#  id                :integer          not null, primary key
#  storefront_id     :integer
#  product_id        :integer
#  supplier_id       :integer
#  order_qty_limit   :integer
#  current_order_qty :integer          default(0)
#  states_applicable :json
#  comments          :text
#  engravable        :boolean
#  active            :boolean
#  starts_at         :datetime
#  ends_at           :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_product_routings_on_product_id     (product_id)
#  index_product_routings_on_storefront_id  (storefront_id)
#  index_product_routings_on_supplier_id    (supplier_id)
#
class ProductRouting < ActiveRecord::Base
  include BarOS::Cache::ProductRoutings

  belongs_to :storefront
  belongs_to :product
  belongs_to :supplier

  validates :order_qty_limit, :starts_at, :supplier, :product, :storefront, presence: true

  has_paper_trail ignore: %i[created_at updated_at]

  scope :by_active, ->(active) { where(active: active) }
  scope :by_name, lambda { |name|
    joins(:product, :supplier)
      .where('products.name ILIKE :name OR suppliers.name ILIKE :name', name: "%#{name}%")
  }
end
