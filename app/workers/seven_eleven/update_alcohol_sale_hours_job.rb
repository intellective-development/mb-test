# frozen_string_literal: true

module SevenEleven
  # UpdateAlcoholSaleHoursJob is a class that updates the alcohol sale hours based on the given sale hours from inventory process
  class UpdateAlcoholSaleHoursJob
    include Sidekiq::Worker
    include WorkerErrorHandling

    sidekiq_options retry: 3,
                    queue: 'inventory_updates',
                    lock: :until_executed

    def perform_with_error_handling(supplier_id, sale_hours)
      return if sale_hours.blank?

      supplier = Supplier.find(supplier_id)

      supplier.shipping_methods.each do |shipping_method|
        hashed_sale_hours = store_hours_to_hash(JSON.parse(sale_hours))
        shipping_method.update!(hours_config: hashed_sale_hours)
      end
    end

    private

    def store_hours_to_hash(store_hours)
      hash = {}
      store_hours.each_key do |key|
        store_hours[key].each do |hour|
          hash[key.to_sym] ||= {}
          hash[key.to_sym][hour[0]] = hour[1]
        end
      end
      hash
    end
  end
end
