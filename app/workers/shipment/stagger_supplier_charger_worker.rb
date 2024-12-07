# frozen_string_literal: true

# This worker is used to stagger the supplier charge for a shipment. It is
# intended to be used in conjunction with the StaggerBusinessChargerWorker
# and should be called after the business charge has been enqueued.
class Shipment::StaggerSupplierChargerWorker # rubocop:disable Style/ClassAndModuleChildren
  attr_reader :shipment_id

  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(shipment_id)
    @shipment_id = shipment_id

    return unless shipment.staggered? # in case any siblings shipment fails

    charges = Charges::ChargeOrderService.create_and_authorize_shipment_charges([shipment])
    if charges.all?(&:authorized_or_settling?)
      shipment.transition_to!(:paid)

      non_paid_sibling = shipment.sibling_shipments.not_in_state(:paid)
      return if non_paid_sibling.present?

      Charges::ChargeOrderService.verify_order(order, all_charges_from_order)
      order.bar_os_order_send!(:order_finalized)
    else
      shipment.transition_to!(:pending)
      order.cancel_finalize
      order.bar_os_order_send!(:order_failed)
      Charges::ChargeOrderService.rollback(all_shipments, all_charges_from_order, 'Not all charges authorized')
    end
  end

  def shipment
    @shipment ||= Shipment.find(shipment_id)
  end

  def order
    @order ||= shipment.order
  end

  def all_shipments
    @all_shipments ||= order.shipments
  end

  def all_charges_from_order
    shipments_charges = all_shipments.map(&:shipment_charges).flatten
    order_charges = order.order_charges
    shipments_charges + order_charges
  end
end
