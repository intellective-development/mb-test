module Fraud
  class VerificationEvent < Event
    def initialize(user, session, request, type:, status:)
      @type = type
      @status = status
      super(user, session, request)
    end

    def self.event_type
      '$verification'
    end

    def properties
      props = super
      props['$status']             = @status # $pending | $success | $failure
      props['$verified_event']     = '$login'
      props['$verified_entity_id'] = @session_id
      props['$verification_type']  = @type
      props['$verified_value']     = @user&.email if @type == '$email'
      props['$reason']             = '$automated_rule'
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

      VerificationEvent.new(
        user,
        session,
        request,
        type: authenticated_session.notification_type,
        status: authenticated_session.verification_status
      )
    end
  end
end
