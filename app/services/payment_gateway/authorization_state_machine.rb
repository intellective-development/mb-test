module PaymentGateway
  class AuthorizationStateMachine
    include Statesman::Machine

    state :pending, initial: true
    state :authorized
    state :declined
    state :failed

    transition from: :pending, to: %i[authorized declined failed]

    guard_transition(to: :authorized) do |authorization, _transition|
      authorization.result.success?
    end

    guard_transition(to: :declined) do |authorization, _transition|
      authorization.transaction_status == 'processor_declined'
    end

    after_transition(to: :failed) do |authorization, _transition|
      authorization.notify_sentry
    end

    after_transition after_commit: true do |_authorization, transition|
      MetricsClient::Metric.emit("minibar_web.state_machine.payment_authorization.transition.to.#{transition.to_state}", 1)
    end
  end
end
