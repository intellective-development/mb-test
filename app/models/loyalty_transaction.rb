# == Schema Information
#
# Table name: loyalty_transactions
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  order_id   :integer          not null
#  points     :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_loyalty_transactions_on_order_id  (order_id)
#  index_loyalty_transactions_on_user_id   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (order_id => orders.id)
#  fk_rails_...  (user_id => users.id)
#

class LoyaltyTransaction < ActiveRecord::Base
  include Statesman::Adapters::ActiveRecordQueries
  include MachineAdapter

  belongs_to :user
  belongs_to :order

  has_many :loyalty_transaction_transitions, autosave: false
  has_one :last_loyalty_transaction_transition, -> { where(most_recent: true) }, class_name: 'LoyaltyTransactionTransition'

  validates :user_id, :order_id, :points, presence: true

  after_commit :schedule_check_on_transactions_order_state, on: :create

  ORDERS_NEEDED_FOR_REWARD = 5

  #-----------------------------------
  # State Machine
  #-----------------------------------
  statesman_machine machine_class: LoyaltyTransactionStateMachine, transition_class: LoyaltyTransactionTransition

  #-----------------------------------
  # Instance Methods
  #-----------------------------------

  private

  def schedule_check_on_transactions_order_state
    LoyaltyTransactionAwardWorker.perform_in(6.hours, id)
  end
end
