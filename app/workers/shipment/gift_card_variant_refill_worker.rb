class Shipment::GiftCardVariantRefillWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(shipment_id)
    Shipment.find(shipment_id).order_items.each do |order_item|
      variant = order_item.variant
      next unless variant.gift_card? && variant.inventory

      new_count = variant.inventory.count_on_hand + order_item.quantity
      variant.inventory.update_attribute(:count_on_hand, new_count)
      variant.touch
    end
  end
end
