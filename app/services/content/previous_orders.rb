module Content
  class PreviousOrders
    attr_reader :config, :options

    # Options
    # =======
    # - `user_id`, which user's orders to return
    def initialize(options)
      @cart_shares = cart_shares(options[:user_id])
      generate_config
    end

    def generate_config
      @config = { cart_shares: @cart_shares }
    end

    private

    MAX_RESULTS = 9

    def cart_shares(user_id)
      CartShare.where(user_id: user_id, share_type: CartShare.share_types[:past_order]).order(created_at: :desc).limit(MAX_RESULTS).select(:id).as_json
    end
  end
end
