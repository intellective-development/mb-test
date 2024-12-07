module Fraud
  class UpdatePasswordEvent < Event
    def initialize(user, session, request, reason:, status: '$success')
      @reason = reason
      @status = status
      super(user, session, request)
    end

    def self.event_type
      '$update_password'
    end

    def properties
      super.except('$time').merge(
        '$reason' => @reason,
        '$status' => @status
      )
    end
  end
end
