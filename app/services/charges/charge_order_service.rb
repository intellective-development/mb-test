module Charges
  class ChargeOrderService
    def self.create_and_authorize_charges(order, shipments)
      shipments = order.shipments if shipments.empty?
      already_charged_service_fee = order.order_charges.any?(&:consider_charged?)

      uncharged_shipments = get_uncharged_shipments(order, shipments)

      unless uncharged_shipments.empty?
        charges = []
        charges += create_and_authorize_shipment_charges(uncharged_shipments)
        charges += create_and_authorize_business_charge(order, uncharged_shipments, already_charged_service_fee)

        raise StandardError, 'Not all charges authorized' unless charges.all?(&:authorized_or_settling?)

        uncharged_shipments.each do |shipment|
          shipment.transition_to!(:paid)
        end

        verify_order(order, charges) if order.placed?

        if ENV['KAFKA_KIT_ENABLED'].to_s == 'true'
          # not all was paid
          order.bar_os_order_send!(order.shipments.any? { |s| s.pending? || s.test? || s.canceled? } ? :update : :paid)
        end
      end

      true
    rescue StandardError => e
      Rails.logger.error "Error while creating charges for shipments: #{e.message}"
      rollback(uncharged_shipments, charges || [], e)
      send_update_declined_payment_method_email(charges)
      false
    end

    def self.send_update_declined_payment_method_email(charges)
      first_notifiable_charge = charges.find { (_1.declined? || _1.voided?) && (_1.shipment&.customer_placement_pre_sale? || _1.shipment&.customer_placement_back_order?) }
      return if first_notifiable_charge.nil?

      first_notifiable_charge.order.create_payment_profile_update_link
      CustomerNotifier.update_payment_profile_link(first_notifiable_charge.order).deliver_later
    end

    def self.verify_order(order, charges)
      to_global_id = ->(charge) { String(charge.to_global_id) }
      order.trigger!(:verify, charges: charges.map(&to_global_id))
    end

    def self.get_uncharged_shipments(order, shipments)
      shipments.select do |shipment|
        shipment.order_id == order.id && # Avoid shipments from other orders
          shipment.shipment_charges.none?(&:consider_charged?) # Avoid already charged shipments
      end
    end

    def self.create_and_authorize_shipment_charges(shipments)
      charges = []

      shipments.each do |shipment|
        next unless shipment.total_supplier_charge.to_f.positive?

        chargeable = shipment.shipment_charges.build({ amount: shipment.total_supplier_charge })
        charge = chargeable.build_charge
        chargeable.save!
        charge.authorize!(submit_for_settlement: true)
        charges << charge
      end

      charges
    end

    def self.create_and_authorize_business_charge(order, shipments, already_charged_service_fee)
      amount = 0
      charges = []

      unless already_charged_service_fee
        # Order Service Fee
        amount += order.amounts.service_fee_after_discounts
        # Video gift fee
        amount += order.amounts.video_gift_fee
        # Membership tax
        amount += order.amounts.membership_tax.to_f
      end

      # Shipments taxes and fees
      shipments.each do |shipment|
        amount += shipment.total_minibar_charge
      end

      return charges if amount.to_f.zero?

      supplier_id = order.storefront.business.fee_supplier.id
      chargeable = order.order_charges.build(amount: amount, supplier_id: supplier_id, description: 'Taxes and Fees')
      charge = chargeable.build_charge
      chargeable.save!
      charge.authorize!(submit_for_settlement: true)

      charges << charge
    end

    def self.rollback(shipments, charges, error)
      rollback_shipment_paid_transition(shipments, error)
      rollback_charges(charges)
    end

    def self.rollback_shipment_paid_transition(shipments, error)
      notes_service = Dashboard::Integration::Notes.new('Charges::ChargeOrderService', RegisteredAccount.super_admin)
      shipments.each do |shipment|
        shipment.cancel_payment if shipment.paid? && shipment.customer_placement_standard?

        next if shipment.customer_placement_standard?

        notes_service.add_note(shipment, "<- Failed to charge customer: #{error.message}")
        exception_metadata = { type: 'payment_error', description: error.message, metadata: { payment_error: error.message } }
        shipment.transition_to!(:exception, exception_metadata) unless shipment.exception?
      end
    end

    def self.rollback_charges(charges)
      charges.each { |charge| charge.cancel! if charge.can_be_cancelled? }
    end

    def self.rollback_charges_for_shipment(shipment, time = nil)
      shipment_charge_time = cancel_last_shipment_charge(shipment, time)
      cancel_last_order_charge(shipment.order, shipment_charge_time)
    end

    def self.cancel_last_shipment_charge(shipment, time = nil)
      last_charge = shipment.shipment_charges.last

      last_charge.cancel! if last_charge.is_a?(Charge) && last_charge.created_at >= time
      last_charge.created_at
    end

    def self.cancel_last_order_charge(order, time)
      last_charge = order.order_charges.last
      last_charge.cancel! if last_charge.is_a?(Charge) && last_charge.created_at >= time
    end
  end
end
