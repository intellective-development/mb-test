class User
  class ActivateAccount
    def initialize(user_id)
      @user = User.includes(:account).find(user_id)
    end

    def call
      @user.account.activate!
    end
  end
end
