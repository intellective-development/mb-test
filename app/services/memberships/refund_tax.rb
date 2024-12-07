module Memberships
  class RefundTax < Base
    def initialize(membership:, user:)
      @membership = membership
      @user = user
    end

    def call
      params = { amount: order.membership_tax, financial: true, credit: true }.merge(default_params)

      OrderAdjustmentCreationService.new(shipment, params, true).process_now!
      @success = shipment.save!
      self
    end

    private

    def order
      @order ||= Order.find_by(membership: membership, membership_plan_id: membership.membership_plan_id)
    end

    def shipment
      @shipment ||= order.shipments.first
    end

    def default_params
      {
        reason_id: OrderAdjustmentReason.find_by_name('Order Change - Item Removed from Order (Not OOS, Customer Requested)').id,
        description: 'Refund membership.',
        user_id: user&.id
      }
    end
  end
end
