# frozen_string_literal: true

module Dashboard
  module Integration
    module ShipStation
      module Models
        class Order
          attr_accessor :id, :items, :ship_to, :bill_to, :order_number, :order_date, :delivery_notes, :gift_detail, :total_amount, :shipping_fee, :tax_amount, :storefront_name, :store_id
        end

        class Item
          attr_accessor :sku, :qty, :name, :price, :engraving
        end

        class Address
          attr_accessor :name, :company, :address1, :address2, :city, :state, :zip_code, :country, :phone
        end
      end
    end
  end
end
