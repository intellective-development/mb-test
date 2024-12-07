# == Schema Information
#
# Table name: product_merges
#
#  id                  :integer          not null, primary key
#  destination_id      :integer
#  source_id           :integer
#  user_id             :integer
#  state               :string(255)
#  options             :hstore
#  original_attributes :hstore
#  source_children     :integer          default([]), is an Array
#  created_at          :datetime
#  updated_at          :datetime
#  mergeable_type      :string(255)      default("Product")
#
# Indexes
#
#  index_product_merges_on_destination_id  (destination_id)
#  index_product_merges_on_source_id       (source_id)
#

class ProductMerge < ActiveRecord::Base
  belongs_to :user

  belongs_to :destination, polymorphic: true, foreign_type: :mergeable_type
  belongs_to :source,      polymorphic: true, foreign_type: :mergeable_type

  state_machine initial: :merged do
    state :reverted

    event :undo do
      transition to: :reverted, from: :merged
    end

    before_transition to: :reverted, do: [:undo_merge!]
  end

  def undo_merge!
    ActiveRecord::Base.transaction do
      raise 'Unable to rollback' unless can_rollback?

      destination.update(original_attributes)
      source.update(state: 'pending') # similarity in updating state on PG's and Products would be helpful here

      case mergeable_type
      when 'Product'
        destination.variants.where(id: source_children).update_all(product_id: source.id)
      when 'ProductSizeGrouping'
        destination.products.where(id: source_children).update_all(product_grouping_id: source.id)
      else
        raise 'Unrecognized Mergeable Type'
      end
    end
  end

  def items_have_volume?
    mergeable_type == 'Product'
  end

  def items_have_products?
    mergeable_type == 'ProductSizeGrouping'
  end

  def can_rollback?
    source && destination && state == 'merged' && destination.state != 'merged'
  end
end
