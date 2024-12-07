module Fraud
  class SecurityNotificationEvent < Event
    def initialize(user, session, request, type:, status:)
      @type = type
      @status = status
      super(user, session, request)
    end

    def self.event_type
      '$security_notification'
    end

    def properties
      props = super
      props['$notification_type']   = @type        # $email | $sms | $push
      props['$notification_status'] = @status      # $sent | $safe | $compromised
      props['$notified_value']      = @user&.email if @type == '$email'
      props
    end

    def self.from_authenticated_session(authenticated_session)
      user = User.find(authenticated_session.user_id)
      session = Struct.new(
        :id
      ).new(
        authenticated_session.session_id
      )
      request = Struct.new(
        :remote_ip,
        :user_agent
      ).new(
        authenticated_session.ip,
        authenticated_session.user_agent
      )

      SecurityNotificationEvent.new(
        user,
        session,
        request,
        type: authenticated_session.notification_type,
        status: authenticated_session.notification_status
      )
    end
  end
end
