# == Schema Information
#
# Table name: brand_merges
#
#  id                  :integer          not null, primary key
#  destination_id      :integer
#  source_id           :integer
#  user_id             :integer
#  state               :string
#  options             :hstore
#  original_attributes :hstore
#  mergeable_type      :string           default("Brand")
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  source_subbrands    :integer          default([]), is an Array
#  source_groupings    :integer          default([]), is an Array
#

class BrandMerge < ActiveRecord::Base
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
      source.update(state: 'active')

      destination.sub_brands.where(id: source_subbrands).update_all(parent_brand_id: source.id)
      destination.product_size_groupings.where(id: source_groupings).update_all(brand_id: source.id)
    end
  end

  def can_rollback?
    source && destination && state == 'merged' && destination.state != 'merged'
  end
end
