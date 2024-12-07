module Fraud
  class CreateAccountEvent < Event
    def self.event_type
      '$create_account'
    end

    def properties
      super.merge(
        '$user_email' => @user&.email,
        '$name' => @user&.name
      )
    end
  end
end
