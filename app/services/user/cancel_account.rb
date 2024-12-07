class User
  class CancelAccount
    def initialize(user_id)
      @user = User.includes(:account).find(user_id)
    end

    def call
      @user.account.cancel!
    end
  end
end
