module Fraud
  class UpdateAccountEvent < Event
    def initialize(user, session, request, params)
      @params = params
      super(user, session, request)
    end

    def self.event_type
      '$update_account'
    end

    def properties
      props = super
      props['$user_email'] = @user&.email if @params.key?('email')
      props['$name']       = @user&.name  if @params.key?('first_name') || @params.key?('last_name')
      props
    end
  end
end
