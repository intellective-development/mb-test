class MikmakAPIV1::CartEndpoint < BaseAPIV1
  helpers do
    def update_cart_item(product, quantity)
      cart_item = @cart.product_cart_items.find_by(product_id: product.id)
      if cart_item.present? # otherwise, if item present, update to new quantity
        cart_item.update(quantity: quantity, active: true)
      else
        @cart.add_product(product, quantity)
      end
    end

    def update_cart_item_sku(product_id, quantity = 1)
      product = Product.find_by(id: product_id)
      error!("Product #{product_id} is not valid.") if product.nil?
      error!("Product #{product.name} is not available.") unless product.active?

      update_cart_item(product, quantity)
    end
  end

  resource :cart do
    # desc 'A'
    before do
      # this partner API should only be used for Minibar Storefront
      @cart = ProductCart.create(storefront_id: Storefront::MINIBAR_ID)
    end

    params do
      requires :skus, type: String, default: ''
    end

    post :add do
      skus = params[:skus].split(',')
      skus.each do |item_sku|
        update_cart_item_sku(item_sku)
      end

      present @cart, with: MikmakAPIV1::Entities::Cart
    end
  end
end
