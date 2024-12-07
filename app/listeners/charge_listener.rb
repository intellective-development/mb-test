class ChargeListener < Minibar::Listener::Base
  subscribe_to Charge

  def charge_settled(charge)
    return unless charge.shipment

    ProcessShipmentFinancialOrderAdjustmentsWorker.perform_async(charge.shipment.id)
    # TODO: it should not be necessary to call this twice
    # we are doing it because some order adjustments are not being processed
    ProcessShipmentFinancialOrderAdjustmentsWorker.perform_at(3.hours.from_now, charge.shipment.id)
  end
end
