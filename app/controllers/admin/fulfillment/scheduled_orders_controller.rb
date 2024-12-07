class Admin::Fulfillment::ScheduledOrdersController < Admin::Fulfillment::BaseController
  def index
    @grouped_shipments = Shipment.where('shipments.state = :scheduled_state OR (shipments.state IN (:confirmed_state) AND shipments.scheduled_for > :now)',
                                        scheduled_state: 'scheduled', confirmed_state: %w[ready_to_ship confirmed], now: Date.today.beginning_of_day)
                                 .where.not(scheduled_for: nil)
                                 .includes(%i[supplier order shipment_amount])
                                 .where.not(orders: { state: 'verifying' })
                                 .order(scheduled_for: :asc, id: :desc)
                                 .group('date(shipments.scheduled_for), shipments.id, suppliers.id, orders.id, shipment_amounts.id')
                                 .page(params[:page] || 1)
                                 .per(params[:per_page] || 25)
  end
end
