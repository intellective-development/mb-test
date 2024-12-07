class FraudListener
  include SentryNotifiable

  def self.order_flagged_fraud(order)
    # TODO: Take these creates out of here and put them into workers.
    # TODO: Move the subsequent worker calls into OrderListener.
    FraudulentOrder.create(order: order)
    DeviceBlacklist.create(device_udid: order.device_udid, platform: order.platform) if order.device_udid

    order.user.account.cancel unless order.user&.account&.canceled?
  rescue StandardError => e
    notify_sentry_and_log(e, "Exception on FraudListener: #{e}")
  end
end
