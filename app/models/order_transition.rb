# == Schema Information
#
# Table name: order_transitions
#
#  id          :integer          not null, primary key
#  to_state    :string           not null
#  metadata    :text             default({})
#  sort_key    :integer          not null
#  order_id    :integer          not null
#  most_recent :boolean          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_order_transitions_parent_most_recent  (order_id,most_recent) UNIQUE WHERE most_recent
#  index_order_transitions_parent_sort         (order_id,sort_key) UNIQUE
#

class OrderTransition < ActiveRecord::Base
  include Statesman::Adapters::ActiveRecordTransition

  belongs_to :order, inverse_of: :order_transitions

  after_destroy :update_most_recent, if: :most_recent?

  private

  def update_most_recent
    last_transition = order.order_transitions.order(:sort_key).last
    last_transition.update_column(:most_recent, true) if last_transition.present?
  end
end
