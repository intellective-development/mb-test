# frozen_string_literal: true

# This service is used to stagger the business and supplier charges for an order.
class Charges::StaggerChargeService # rubocop:disable Style/ClassAndModuleChildren
  attr_reader :order

  def initialize(order)
    @order = order
  end

  def call
    business_delay, supplier_delay_range = define_delay
    Order::StaggerBusinessChargerWorker.perform_in(business_delay, order.id)
    order.shipments.each do |shipment|
      Shipment::StaggerSupplierChargerWorker.perform_in(rand(supplier_delay_range).minutes, shipment.id)
      shipment.set_as_staggered!
    end
    order.place!
  end

  def define_delay
    most_recent = order.shipments.map(&:scheduled_for).compact.min
    if most_recent.nil? || most_recent > 24.hours.from_now
      [9, (13..19)]
    elsif most_recent < 1.hour.from_now
      [1, (3..5)]
    else
      [4, (7..11)]
    end
  end
end
