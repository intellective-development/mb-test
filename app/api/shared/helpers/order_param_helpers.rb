module Shared::Helpers::OrderParamHelpers
  extend Grape::API::Helpers

  params :replenishment do
    optional :replenishment, type: Hash do
      optional :enabled,  type: Boolean, default: false
      optional :interval, type: Integer, default: 7, desc: 'Re-order interval expressed in days.'
    end
  end

  params :order_items do
    optional :order_items, type: Array do
      optional :delivery_method_id, type: String
      optional :scheduled_for, type: DateTime
      requires :id, type: Integer, allow_blank: false
      given id: ->(id) { !Variant.gift_card?(id) } do
        requires :quantity, type: Integer, default: 1
      end
      use :item_options_params
    end
  end

  params :gift_options do
    optional :has_video_gift_message, type: Boolean
    optional :is_gift, type: Boolean
    optional :gift_options, type: Hash do
      use :gift_detail_params
    end
    optional :gift_detail_id
    mutually_exclusive :gift_options, :gift_detail_id
  end

  params :order_options do
    optional :button_referrer_token,  type: String, allow_blank: true, desc: 'Button referrer token'
    optional :delivery_notes,         type: String, allow_blank: true
    optional :options, type: Hash do
      optional :conditional_tipping, type: Boolean, default: false, allow_blank: false, desc: 'Opt-in for allows_tipping functionality on shipping method'
    end
    optional :coupons,          type: Array, allow_blank: true
    optional :gift_cards,       type: Array, allow_blank: true
    optional :promo_code,       type: String, allow_blank: true
    optional :shoprunner_token, type: String, allow_blank: true, desc: 'ShopRunner user token'
    optional :tip,              type: Float

    mutually_exclusive :gift_cards, :coupons
    mutually_exclusive :promo_code, :coupons
  end

  params :order_create do
    use :gift_options
    use :order_items
    use :order_options
    use :replenishment
    optional :birthdate,              type: String, allow_blank: true
    optional :pickup_detail_id,       type: String, allow_blank: true
    optional :shipping_address_id,    type: String, allow_blank: true
    optional :payment_profile_id,     type: String, allow_blank: true
    optional :session_id,             type: String, allow_blank: false
    optional :cart_id,                type: String, allow_blank: false
    optional :cart,                   type: Hash do
      requires :id, type: String
    end
    optional :payment_profile, type: Hash do
      requires :address, type: Hash do
        optional :address2,     type: String, allow_blank: true, default: ''
        optional :city,         type: String, allow_blank: true
        optional :state,        type: String, allow_blank: true
        requires :address1,     type: String, allow_blank: false
        requires :name,         type: String, allow_blank: false
        requires :zip_code,     type: String, regexp: /^(\d){5}/
      end
      requires :payment_method_nonce, type: String, allow_blank: false
    end
    mutually_exclusive :payment_profile, :payment_profile_id
  end

  params :order_update do
    use :gift_options
    use :order_items
    use :order_options
    use :replenishment
    optional :birthdate,              type: String
    optional :pickup_detail_id,       type: String, allow_blank: true
    optional :shipping_address_id,    type: String, allow_blank: true
    optional :payment_profile_id,     type: String, allow_blank: true
    optional :session_id,             type: String, allow_blank: false
    optional :payment_profile, type: Hash do
      requires :address, type: Hash do
        optional :address2,     type: String, allow_blank: true, default: ''
        optional :city,         type: String, allow_blank: true
        optional :state,        type: String, allow_blank: true
        requires :address1,     type: String, allow_blank: false
        requires :name,         type: String, allow_blank: false
        requires :zip_code,     type: String, regexp: /^(\d){5}/
      end
      requires :payment_method_nonce, type: String, allow_blank: false
    end
    mutually_exclusive :payment_profile, :payment_profile_id
  end

  params :order_finalize do
    use :gift_options
    use :order_items
    use :order_options
    use :replenishment
    optional :birthdate,              type: String
    optional :pickup_detail_id,       type: String, allow_blank: false
    optional :shipping_address_id,    type: String, allow_blank: false
    optional :payment_profile_id,     type: String, allow_blank: false
    optional :session_id,             type: String, allow_blank: false
    optional :age_agreement,          type: Boolean, allow_blank: false
    optional :payment_profile, type: Hash do
      requires :address, type: Hash do
        optional :address2,     type: String, allow_blank: true, default: ''
        optional :city,         type: String, allow_blank: true
        optional :state,        type: String, allow_blank: true
        requires :address1,     type: String, allow_blank: false
        requires :name,         type: String, allow_blank: false
        requires :zip_code,     type: String, regexp: /^(\d){5}/
      end
      requires :payment_method_nonce, type: String, allow_blank: false
    end
    mutually_exclusive :payment_profile, :payment_profile_id
  end
end
