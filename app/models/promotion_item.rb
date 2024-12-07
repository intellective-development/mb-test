# == Schema Information
#
# Table name: promotion_items
#
#  id           :integer          not null, primary key
#  item_id      :integer          not null
#  item_type    :string(255)      not null
#  promotion_id :integer          not null
#  created_at   :datetime
#  updated_at   :datetime
#
# Indexes
#
#  index_promotion_items_on_promotion_id  (promotion_id)
#

class PromotionItem < ActiveRecord::Base
  belongs_to :promotion
  belongs_to :item, polymorphic: true
end
