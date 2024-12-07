class SupplierAPIV2::VariantEndpoint < BaseAPIV2
  namespace :product do
    before do
      @variant = begin
        current_supplier.variants.find(params[:variant_id])
      rescue StandardError
        new_variant = Supplier.find_by(name: 'Inventory Template Store').variants.active.find(params[:variant_id]).dup
        new_variant.supplier_id = current_supplier.id
        new_variant.create_inventory(count_on_hand: 0)
        new_variant.save!
        new_variant
      end
    end
    params do
      requires :variant_id, type: String
    end
    route_param :variant_id do
      desc 'Load a single product.'
      get do
        return error!('Product not found', 404) unless @variant.active?

        present @variant, with: SupplierAPIV2::Entities::Variant
      end
      params do
        optional :active,        type: Boolean
        optional :price,         type: Float
        optional :sale_price,    type: Float
        optional :inventory,     type: Integer
        optional :case_eligible, type: Boolean
      end
      desc 'Update a variant state, inventory and/or price.'
      put do
        @variant.price      = params[:price]                          if params[:price].present?
        @variant.sale_price = params[:sale_price]                     if params[:sale_price].present?
        @variant.case_eligible = params[:case_eligible]               if params[:case_eligible].present?
        @variant.inventory.update(count_on_hand: params[:inventory])  if params[:inventory].present?

        if @variant.active? && params[:active] == false
          @variant.deleted_at = Time.zone.now
        elsif params[:active] == true
          @variant.deleted_at = nil
        end

        if @variant.save
          present @variant, with: SupplierAPIV2::Entities::Variant
        else
          error!('Unable to update product.', 400)
        end
      end
      desc 'Change product associated to variant'
      put :merge do
        product_variants = Variant.where(product_id: @variant.product_id)
        # For now we will only change the variant's product instead of merging the 2 products.
        target_product = Product.find params['target']
        @variant.product_id = target_product.id
        @variant.save
      end
    end
  end
end
