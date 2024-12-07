# == Schema Information
#
# Table name: loyalty_transaction_transitions
#
#  id                     :integer          not null, primary key
#  to_state               :string           not null
#  metadata               :json
#  sort_key               :integer          not null
#  loyalty_transaction_id :integer          not null
#  most_recent            :boolean          not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_loyalty_transaction_transitions_parent_most_recent  (loyalty_transaction_id,most_recent) UNIQUE WHERE most_recent
#  index_loyalty_transaction_transitions_parent_sort         (loyalty_transaction_id,sort_key) UNIQUE
#

class LoyaltyTransactionTransition < ActiveRecord::Base
  belongs_to :loyalty_transaction, inverse_of: :loyalty_transaction_transitions

  after_destroy :update_most_recent, if: :most_recent?

  private

  def update_most_recent
    last_transition = loyalty_transaction.loyalty_transaction_transitions.order(:sort_key).last
    return if last_transition.blank?

    last_transition.update_column(:most_recent, true)
  end
end
