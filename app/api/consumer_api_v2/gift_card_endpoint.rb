class ConsumerAPIV2::GiftCardEndpoint < BaseAPIV2
  format :json

  resource :gift_cards do
    desc 'Returns gift cards options.', ConsumerAPIV2::DOC_AUTH_HEADER
    get do
      Rails.cache.fetch('api::v2::gift_cards::get', expires_in: 60.minutes) do
        product_groupings = ProductGrouping.active
                                           .includes(products: [:variants])
                                           .where(products: { state: 'active' })
                                           .where(variants: { options_type: Variant.options_types[:gift_card] })
                                           .all

        product_groupings = product_groupings.joins(:gift_card_theme).where(gift_card_themes: { is_custom: false, storefront_id: Storefront::MINIBAR_ID })

        suppliers_ids = product_groupings.distinct.pluck 'variants.supplier_id'

        suppliers = Supplier.includes(:profile, :shipping_methods, :supplier_type, :supplier_logos, :delivery_hours, :address)
                            .where(id: suppliers_ids)
                            .order(:supplier_type_id, :name)

        shipping_methods = ShippingMethod.includes(:supplier)
                                         .active
                                         .where(supplier_id: suppliers_ids.select { |b| b.to_s[/\d+$/] })

        present :product_groupings, product_groupings.map { |p| p.view.entity(business: storefront.business) }
        present :suppliers, ConsumerAPIV2::Entities::Supplier.represent(suppliers,
                                                                        shipping_methods: shipping_methods)
      end
    end

    route_param :code do
      get do
        coupon = CouponDecreasingBalance.active.find_by(code: params[:code], storefront: storefront)

        present coupon, with: ConsumerAPIV2::Entities::CouponDecreasingBalance
      end
    end
  end
end
