class Order
  class ClaimGuestOrders
    attr_reader :account

    delegate :user, to: :account

    def initialize(account)
      # reload account to reload it's user relationship
      @account = account
    end

    def call
      all_user_ids = User.where(account_type: 'RegisteredAccount')
                         .joins('INNER JOIN registered_accounts ON users.account_id = registered_accounts.id')
                         .where("registered_accounts.contact_email": account.email).pluck('users.id')

      all_user_ids.each do |user_id|
        Order.where(user_id: user_id).update(user_id: user.id)
      end
    end
  end
end
