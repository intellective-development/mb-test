module Dashboard
  module Integration
    module Specs
      module Models
        class Order
          attr_accessor :id, :items, :customer_details, :summary, :delivery, :store_number, :tip, :order_reference_number, :fulfillment_time
        end

        class Delivery
          attr_accessor :shipping_details, :order_special_instructions
        end

        class OrderSummary
          attr_accessor :tax_rate, :tax_total, :total, :subtotal, :fees_total
        end

        class Item
          attr_accessor :primary_upc, :name, :qty, :price, :tax_exempt
        end

        class CustomerDetails
          attr_accessor :first_name, :last_name, :email, :phone, :street_1, :street_2, :city, :state, :zip
        end
      end
    end
  end
end
