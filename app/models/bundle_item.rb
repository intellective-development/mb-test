# == Schema Information
#
# Table name: bundle_items
#
#  id         :integer          not null, primary key
#  bundle_id  :integer
#  item_type  :string
#  item_id    :integer
#  active     :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_bundle_items_on_bundle_id              (bundle_id)
#  index_bundle_items_on_item_type_and_item_id  (item_type,item_id)
#
# Foreign Keys
#
#  fk_rails_...  (bundle_id => bundles.id)
#

# To understand this model more please look at the documentation in the CART.rb model
class BundleItem < ActiveRecord::Base
  belongs_to :bundle, touch: true
  belongs_to :item, polymorphic: true

  before_validation :set_item, if: :item_attributes_changed?

  # validates :bundle_id, presence: true
  validates :item_id, presence: true
  validates :item_type, presence: true

  accepts_nested_attributes_for :item

  def item_attributes_changed?
    item_type_changed? || item_id_changed?
  end

  def set_item
    return unless item_type && item_id

    item_class = item_type.classify.constantize
    self.item = item_class.friendly.find(item_id)
  end
end
