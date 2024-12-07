# == Schema Information
#
# Table name: variant_search_data
#
#  id               :integer          not null, primary key
#  orderer_ids      :integer          default([]), is an Array
#  times_ordered    :integer          default(0)
#  popularity       :integer          default(0)
#  popularity_60day :integer          default(0)
#  variant_id       :integer
#

class VariantSearchData < ActiveRecord::Base
  belongs_to :variant

  def refresh!
    self.orderer_ids             = variant.paid_orderer_ids
    self.times_ordered           = variant.order_items.paid.count
    self.popularity              = variant.paid_sibling_items.count
    self.popularity_60day        = variant.paid_sibling_items.where('order_items.created_at > ?', 60.days.ago).count

    save
  end
end
