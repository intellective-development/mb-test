class Shipment::CancelTestShipmentService
  # @param [Shipment] shipment
  def self.test_shipment?(shipment)
    user = shipment.order.user
    order_email = shipment.order.email
    user_email = user.account.email

    test = test_email?(order_email) || test_email?(user_email)

    CancelTestShipmentWorker.perform_at(1.minute.from_now, shipment.id) if test

    test
  end

  def self.test_email?(email)
    /\+testcancel@(reservebar\.com|minibardelivery\.com|clevertech\.biz)$/i.match?(email)
  end
end
