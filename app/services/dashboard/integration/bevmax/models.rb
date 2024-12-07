module Dashboard
  module Integration
    module Bevmax
      module Models
        class Order
          attr_accessor :id, :items, :ship_to, :bill_to, :store_number, :tip, :order_reference_number, :business,
                        :delivery_notes, :gift_detail, :total_tax, :shipping_cost, :total_discount, :total_amount

          def reservebar?
            Business::RESERVEBAR_ID == business.id
          end

          def minibar?
            Business::MINIBAR_ID == business.id
          end
        end

        class Item
          attr_accessor :sku, :qty, :price, :tax_exempt, :engraving
        end

        class Address
          attr_accessor :name, :email, :phone, :address1, :address2, :city, :state, :zip_code, :country
        end
      end
    end
  end
end
