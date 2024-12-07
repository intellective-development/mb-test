module Dashboard
  module Integration
    module SevenEleven
      module Builder
        class PaymentDetailsBuilder
          attr_reader :payment_details

          def self.build
            builder = new
            yield(builder)
            builder.payment_details
          end

          def initialize(_existing_shipping = nil)
            @payment_details = Dashboard::Integration::SevenEleven::Models::PaymentDetails.new
          end

          def set_transaction_id(id)
            @payment_details.transaction_id = id
          end

          def set_gateway(gateway)
            @payment_details.gateway = gateway
          end

          def set_amount(amount)
            @payment_details.amount = (amount * 100).to_i
          end

          def set_promo_amount(amount)
            @payment_details.partner_promo_amount = (amount * 100).to_i
          end

          def set_gift_card_amount(amount)
            @payment_details.partner_gift_card_amount = (amount * 100).to_i
          end

          def set_cc_brand(brand)
            @payment_details.brand = brand
          end

          def mark_as_card_payment
            set_payment_mode('card')
          end

          def set_cc_first6(cc_number)
            @payment_details.first6 = cc_number[0...6]
          end

          def set_cc_last4(cc_number)
            @payment_details.last4 = cc_number[-4..]
          end

          def set_funding(funding)
            @payment_details.funding = funding
          end

          def mark_as_usd_transaction
            set_currency('USD')
          end

          private

          def set_currency(currency)
            @payment_details.currency = currency
          end

          def set_payment_mode(payment_mode)
            @payment_details.payment_mode = payment_mode
          end
        end
      end
    end
  end
end
