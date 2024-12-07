class User
  module LoyaltyMethods
    def loyalty_point_balance
      {
        finalized: loyalty_transactions.in_state(:finalized).sum(:points),
        pending: loyalty_transactions.in_state(:pending).sum(:points),
        voided: loyalty_transactions.in_state(:voided).sum(:points)
      }
    end

    def earned_loyalty_reward?
      points = loyalty_transactions.in_state(:finalized).sum(:points)
      !points.zero? && (points % LoyaltyTransaction::ORDERS_NEEDED_FOR_REWARD).zero?
    end

    def points_until_loyalty_reward
      remaining_points = (loyalty_transactions.in_state(:finalized).sum(:points) % reward_quota)
      remaining_points.zero? ? 0 : LoyaltyTransaction::ORDERS_NEEDED_FOR_REWARD - remaining_points
    end
  end
end
