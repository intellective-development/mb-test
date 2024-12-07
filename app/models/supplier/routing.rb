class Supplier
  module Routing
    #-----------------------------------
    # Class methods
    #-----------------------------------

    # Intended to be ran daily via. cron job to reset any temporary changes made
    # to boosting.
    #
    # Potentially we could incorporate dynamic rebalancing here by setting the
    # boost factor based on other variables such as # of orders or $ revenue.
    def self.reset_temporary_boost_factors
      Supplier.update_all(temporary_boost_factor: 0)
    end

    #-----------------------------------
    # Instance methods
    #-----------------------------------

    def total_boost_factor
      boost_factor + temporary_boost_factor
    end

    def adjusted_score
      Math.exp(score || 4.5)
    end

    def add_strike(penalty = 3)
      update(temporary_boost_factor: new_boost(penalty))
    end

    def add_strike!(penalty = 3)
      update!(temporary_boost_factor: new_boost(penalty))
    end

    private

    def new_boost(penalty)
      new_boost = temporary_boost_factor - penalty
      new_boost < -10 ? -10 : new_boost
    end
  end
end
