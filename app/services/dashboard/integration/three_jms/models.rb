module Dashboard
  module Integration
    module ThreeJMS
      module Models
        class Order
          attr_accessor :id, :order_uuid, :order_type, :brand, :email, :phone, :items, :ship_to, :gift_detail, :qr_code
        end

        class Item
          attr_accessor :sku, :qty, :name, :price, :engraving
        end

        class Address
          attr_accessor :name, :company, :address1, :address2, :city, :state, :zip_code, :country
        end

        class Comment
          attr_accessor :note, :user, :file
        end
      end
    end
  end
end
