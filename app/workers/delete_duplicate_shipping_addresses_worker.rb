# frozen_string_literal: true

# DeleteDuplicateShippingAddressesWorker
#
# Worker for removing duplicate shipping addresses
class DeleteDuplicateShippingAddressesWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'internal'

  def perform_with_error_handling(user_id)
    user = User.find(user_id)

    full_address_id = {}
    return unless user.shipping_addresses.present?

    user.shipping_addresses.order(:id).each do |address|
      full_address = [address.address_lines, address.city_state_zip].join(', ')
      if full_address_id[full_address].present? && full_address_id[full_address] != address.id
        orders = Order.where(ship_address_id: address.id)
        orders.map { |order| order.update_attribute(:ship_address_id, full_address_id[full_address]) }
        address.destroy
      else
        full_address_id[full_address] = address.id
      end
    end
    user.shipping_addresses.last.update(default: true) unless user.default_shipping_address.present?
  end
end
