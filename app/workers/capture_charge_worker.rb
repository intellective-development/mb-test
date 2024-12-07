class CaptureChargeWorker
  include Sidekiq::Worker
  include WorkerErrorHandling
  include SentryNotifiable

  sidekiq_options retry: true,
                  queue: 'internal',
                  lock: :until_and_while_executing

  def perform_with_error_handling(charge_gid)
    charge = GlobalID.find(charge_gid)

    charge.capture! unless charge.settling? || charge.settled?
  rescue *PaymentGateway::TransactionalBase::RETRYABLES => e
    notify_sentry_and_log(e)
    raise e
  rescue StandardError => e
    # TODO: Remove when [TECH-2504] is solved
    notify_sentry_and_log(e,
                          "CaptureChargeWorker Error. #{e.message}",
                          { tags: { charge_id: charge&.id, exception: e.message } })
  end
end
