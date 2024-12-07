module Fraud
  class LoginEvent < Event
    def initialize(user, session, request, success:, failure_reason: nil)
      @success = success
      @failure_reason = sift_failure_reason_of(failure_reason) unless success
      super(user, session, request)
    end

    def self.event_type
      '$login'
    end

    def properties
      props = super
      props['$username']       = @user&.email
      props['$login_status']   = @success ? '$success' : '$failure'
      props['$failure_reason'] = @failure_reason if @failure_reason
      props
    end

    def call_and_run_workflow
      response = notify_sift(
        self.class.event_type,
        properties,
        return_workflow_status: true,
        abuse_types: ['account_takeover']
      )
      {
        score: response&.body&.dig('score_response', 'scores', 'account_takeover', 'score'),
        decision: response&.body&.dig('score_response', 'workflow_statuses')&.first&.dig('history')&.find { |app| app['app'] == 'decision' }&.dig('config', 'decision_id')
      }
    end

    private

    def sift_failure_reason_of(failure_reason)
      case failure_reason
      when 'invalid'
        return '$wrong_password'
      when 'not_found_in_database'
        return '$account_unknown'
      when /^\$/
        return failure_reason
      end
      nil
    end
  end
end
