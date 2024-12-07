module Fraud
  class LogoutEvent < Event
    def self.event_type
      '$logout'
    end
  end
end
