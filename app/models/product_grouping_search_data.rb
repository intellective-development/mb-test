# == Schema Information
#
# Table name: product_grouping_search_data
#
#  id                       :integer          not null, primary key
#  orderer_ids              :integer          default([]), is an Array
#  orderer_ids_60day        :integer          default([]), is an Array
#  times_ordered            :integer          default(0)
#  popularity               :integer          default(0)
#  popularity_60day         :integer          default(0)
#  frequently_ordered_with  :integer          default([]), is an Array
#  product_size_grouping_id :integer
#  created_at               :datetime
#  updated_at               :datetime
#
# Indexes
#
#  index_product_grouping_search_data_on_product_size_grouping_id  (product_size_grouping_id)
#

# none of this stuff is used anymore, so disabling it for now
# in the future, perhaps look at what Shipment::with_product_grouping is doing and use most of that

class ProductGroupingSearchData < ActiveRecord::Base
  belongs_to :product_size_grouping

  def refresh!
    paid_order_items = product_size_grouping.paid_order_items

    # self.orderer_ids             = product_size_grouping.paid_orderer_ids.uniq
    self.orderer_ids_60day       = product_size_grouping.paid_orders.merge(OrderItem.where('order_items.created_at < ?', 60.days.ago)).group(:user_id).pluck(:user_id)
    self.times_ordered           = paid_order_items.sum(:quantity)
    self.popularity              = paid_order_items.count
    self.popularity_60day        = paid_order_items.where('order_items.created_at > ?', 60.days.ago).count
    # TODO: should we drop this from 10 to 5? we're going to wind up with a lot of noise products for infrequently purchsed items,
    # since something that's been bought with this item once will be equally as valid as something bought 500 times
    self.frequently_ordered_with = product_size_grouping.frequently_purchased_with(10)

    save
  end

  def incremental_update!
    recent_order_items = product_size_grouping.paid_order_items.where(order_items: { created_at: updated_at..Time.zone.now })

    # TODO: Some of these need futher optimization.
    # self.orderer_ids              = product_size_grouping.paid_orderer_ids.uniq
    self.orderer_ids_60day        = product_size_grouping.paid_orders.merge(OrderItem.where('order_items.created_at < ?', 60.days.ago)).group(:user_id).pluck(:user_id)
    self.times_ordered            = times_ordered + recent_order_items.sum(:quantity)
    self.popularity               = popularity + recent_order_items.count
    self.popularity_60day         = product_size_grouping.paid_order_items.where(order_items: { created_at: 60.days.ago..Time.zone.now }).count
    self.frequently_ordered_with  = product_size_grouping.frequently_purchased_with(10)
    self.updated_at               = Time.now

    save
  end
end
