# frozen_string_literal: true

# This worker is used to stagger the business charge for an order. It is
# intended to be used in conjunction with the StaggerSupplierChargerWorker
# and should be called before the supplier charges have been enqueued.
class Order::StaggerBusinessChargerWorker # rubocop:disable Style/ClassAndModuleChildren
  attr_reader :order_id

  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(order_id)
    @order_id = order_id
    charges = Charges::ChargeOrderService.create_and_authorize_business_charge(order, order.shipments, false)
    return true if charges.all?(&:authorized_or_settling?)

    Charges::ChargeOrderService.rollback_charges(charges)
    order.cancel_finalize
    order.bar_os_order_send!(:order_failed)
  end

  def order
    @order ||= Order.find(order_id)
  end
end
