# frozen_string_literal: true

module PreSales
  # UpdateVariants
  class UpdateVariants
    attr_reader :pre_sale, :params

    def initialize(pre_sale)
      @pre_sale = pre_sale
    end

    def call
      ActiveRecord::Base.transaction do
        @success = upsert_variants

        raise ActiveRecord::Rollback unless success?
      end

      self
    end

    def success?
      @success
    end

    private

    def upsert_variants
      @supplier_product_order_limits = @pre_sale.product_order_limit.supplier_product_order_limits
      @supplier_product_order_limits.each do |spol|
        if spol.variant_id.present?
          @variant = Variant.find(spol.variant_id)

          spol.order_limit.to_i >= 0 ? update_variant(spol) : delete_variant(spol)
        else
          create_variant(spol)
        end
      end

      true
    end

    def create_variant(spol)
      return unless spol.order_limit.to_i >= 0

      variant = Variant.create(
        supplier: spol.supplier,
        product: @pre_sale.product,
        sku: @pre_sale.merchant_sku,
        name: @pre_sale.name,
        original_price: @pre_sale.price,
        price: @pre_sale.price,
        product_active: true,
        frozen_inventory: true
      )

      return unless variant

      variant.create_inventory(count_on_hand: spol.order_limit)
      spol.update(variant_id: variant.id)
    end

    def update_variant(spol)
      return if spol.order_limit == @variant.inventory.count_on_hand

      @variant.inventory.update(count_on_hand: spol.order_limit)
    end

    def delete_variant(spol)
      spol.update(variant_id: nil)
      @variant.inventory.update(count_on_hand: 0)
      @variant.soft_destroy
    end
  end
end
