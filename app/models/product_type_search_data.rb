# == Schema Information
#
# Table name: product_type_search_data
#
#  id               :integer          not null, primary key
#  popularity       :integer          default(0)
#  popularity_60day :integer          default(0)
#  product_type_id  :integer
#  created_at       :datetime
#  updated_at       :datetime
#
# Indexes
#
#  index_product_type_search_data_on_product_type_id  (product_type_id)
#

class ProductTypeSearchData < ActiveRecord::Base
  belongs_to :product_type

  after_save :reindex_product_type

  def refresh!
    paid_order_items = product_type.paid_order_items

    self.popularity       = paid_order_items.count
    self.popularity_60day = paid_order_items.where('order_items.created_at > ?', 60.days.ago).count
    save
  end

  def incremental_update!
    recent_order_items = product_type.paid_order_items.where(order_items: { created_at: updated_at..Time.zone.now })

    self.popularity       = popularity + recent_order_items.count
    self.popularity_60day = product_type.paid_order_items.where(order_items: { created_at: 60.days.ago..Time.zone.now })
    save
  end

  private

  def reindex_product_type
    product_type.reindex
  end
end
