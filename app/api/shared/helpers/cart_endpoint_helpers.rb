module Shared::Helpers::CartEndpointHelpers
  extend Grape::API::Helpers

  def logged_in_and_cart_belongs_to_another_user
    @user && @user.id != @cart.user_id
  end

  def logged_out_and_cart_belongs_to_another_user
    @user.nil? && !@cart.user_id.nil?
  end

  def claim_cart
    @cart.update(user_id: @user.id)
  end

  def in_stock_validation(cart_items)
    quantities = Variant.includes(:inventory).where(id: cart_items.pluck(:variant_id)).pluck(:id, :count_on_hand, :count_pending_to_customer)

    errors = []

    cart_items.each do |item|
      qty = quantities.select { |q| q[0] == item[:variant_id].to_i }.first
      quantity = qty.present? ? [qty[0], qty[1] - qty[2]] : nil
      response = in_stock_item_check(item, quantity)
      errors << response unless response == true
    end

    error!({ type: 'in_stock_validation', data: errors }, 400) unless errors.empty?
  end

  def in_stock_item_validation(item_params)
    variant = Variant.includes(:inventory).find_by(id: item_params[:variant_id])
    quantity = variant.present? ? [variant.id, variant.inventory.count_on_hand - variant.inventory.count_pending_to_customer] : nil
    response = in_stock_item_check(item_params, quantity)

    error!({ type: 'in_stock_validation', data: [response] }, 400) unless response == true
  end

  def in_stock_item_check(item, quantity)
    error!("Product #{item[:variant_id]} is invalid or sold out.", 400) if quantity.nil?

    return { identifier: item[:identifier], available_quantity: quantity[1] } if quantity[1] < item[:quantity]

    true
  end

  def user_address
    return if cookies[:mb_address].blank?

    address_params = JSON.parse(cookies[:mb_address]).transform_keys(&:to_sym)
    address_params[:coords] = { lat: address_params[:latitude], lng: address_params[:longitude] }
    Address.create_from_params(address_params)
  rescue JSON::ParserError
    nil
  end

  def product_bundle(external_id)
    ProductBundle.find_by(external_id: external_id)
  end

  def set_cart_items
    @cart_items = if @params[:cart_items].present?
                    @params[:cart_items].map do |cart_item|
                      {
                        identifier: cart_item[:identifier],
                        variant_id: cart_item[:variant_id] || cart_item[:identifier],
                        quantity: cart_item[:quantity]&.to_i,
                        product_bundle: product_bundle(cart_item[:product_bundle_external_id]),
                        customer_placement: cart_item[:customer_placement] || 0,
                        item_options: cart_item[:options]
                      }
                    end
                  elsif @params[:cart_share_id].present?
                    cart_share_items.map do |cart_share_item|
                      {
                        identifier: cart_share_item[:variant]&.id,
                        variant_id: cart_share_item[:variant]&.id,
                        quantity: cart_share_item[:quantity]&.to_i,
                        product_bundle: product_bundle(cart_share_item[:product_bundle_external_id]),
                        customer_placement: cart_share_item[:customer_placement] || 0
                      }
                    end
                  else # no changes on cart_items
                    []
                  end
  end

  def cart_share
    CartShare.includes(:cart_share_items).find_by(id: @params[:cart_share_id]) || error!('CartShare not found', 404)
  end

  def cart_share_items
    supplier_ids = @params[:supplier_ids]
    error!('CartShare can not be applied without supplier_ids', 400) unless supplier_ids&.any?

    cart_share.get_items_for_suppliers(supplier_ids)
  end

  def update_cart_trait
    coupon_code = @params[:coupon_code]
    gtm_visitor_id = @params[:gtm_visitor_id]
    decision_log_uuids = @params[:decision_log_uuids]
    membership_plan_id = @params[:membership_plan_id]
    gift_order = @params.key?('gift_order')
    age_verified = @params.key?('age_verified')

    return unless coupon_code || gtm_visitor_id || decision_log_uuids || gift_order || age_verified || membership_plan_id

    cart_trait = @cart.cart_trait
    cart_trait ||= CartTrait.new(cart: @cart)

    cart_trait.coupon_code = coupon_code
    cart_trait.gtm_visitor_id = gtm_visitor_id
    cart_trait.decision_log_uuids = (cart_trait.decision_log_uuids || {}).deep_merge(decision_log_uuids || {})
    cart_trait.membership_plan_id = membership_plan_id

    # if we get null and set it as null, it doesnt get to be the default (false)
    cart_trait.gift_order = @params[:gift_order] if gift_order
    cart_trait.age_verified = @params[:age_verified] if age_verified

    cart_trait.save
  end

  def use_in_stock_check?
    storefront.default_storefront? || !!storefront.enable_in_stock_check
  end
end
