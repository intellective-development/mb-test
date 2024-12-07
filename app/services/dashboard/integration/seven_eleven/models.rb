module Dashboard
  module Integration
    module SevenEleven
      module Models
        class Order
          attr_accessor :store_id, :order_type, :items, :fee_items, :shipping, :payment_details, :tip, :user_profile, :commission_rate, :commission_amt, :fees, :meta_info
        end

        class Item
          attr_accessor :item_id, :name, :price, :qty
        end

        class Shipping
          attr_accessor :city, :state, :zip, :street, :lat, :lng, :delivery_notes
        end

        class PaymentDetails
          attr_accessor :transaction_id, :gateway, :amount, :brand, :payment_mode, :first6, :last4, :currency, :funding, :partner_gift_card_amount, :partner_promo_amount

          def validate
            raise Error::StandardError, 'Missing transaction id on PaymentDetails model' if transaction_id.nil?
            raise Error::StandardError, 'Missing gateway on PaymentDetails model' if gateway.nil?
            raise Error::StandardError, 'Missing amount on PaymentDetails model' if amount.nil?
            raise Error::StandardError, 'Missing payment mode on PaymentDetails model' if payment_mode.nil?
            raise Error::StandardError, 'Missing brand on PaymentDetails model' if brand.nil?
            raise Error::StandardError, 'Missing first 6 on PaymentDetails model' if first6.nil?
            raise Error::StandardError, 'Missing last 4 on PaymentDetails model' if last4.nil?
            raise Error::StandardError, 'Missing currency on PaymentDetails model' if currency.nil?
            raise Error::StandardError, 'Missing funding on PaymentDetails model' if funding.nil?

            raise Error::StandardError, 'Invalid payment_mode on PaymentDetails model' unless %w[card ApplePay googlePay].include?(payment_mode)

            raise Error::StandardError, 'Invalid funding on PaymentDetails model' unless %w[credit debit prepaid unknown].include?(funding)

            raise Error::StandardError, 'Invalid first 6 on PaymentDetails model' if first6.length != 6
            raise Error::StandardError, 'Invalid last 4 on PaymentDetails model' if last4.length != 4
            raise Error::StandardError, 'Invalid currency on PaymentDetails model' if currency != 'USD'
          end
        end

        class UserProfile
          attr_accessor :first_name, :last_name, :phone_number
        end
      end
    end
  end
end
