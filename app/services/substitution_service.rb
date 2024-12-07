class SubstitutionService
  attr_accessor :shipment, :order, :order_item, :sku, :quantity, :quantity_to_replace, :onus, :custom_price, :current_supplier_id

  def initialize(substitution_params)
    @shipment = substitution_params[:shipment]
    @order_item = substitution_params[:order_item]
    @sku = substitution_params[:sku]
    @quantity = substitution_params[:quantity]
    @quantity_to_replace = substitution_params[:quantity_to_replace]
    @custom_price = substitution_params[:custom_price] # optional
    @current_supplier_id = substitution_params[:supplier_id]
  end

  def get_substitute_variant
    Variant.find_by(sku: @sku, supplier_id: @current_supplier_id)
  end

  def get_order_item_substitutions
    Substitution.where(original_id: @order_item.id).where.not(status: :cancelled)
  end

  def get_substitute_order_item(substitute_variant)
    variant_price = @custom_price || substitute_variant.price
    substitute_order_item = OrderItemTemp.new(variant: substitute_variant, quantity: @quantity, price: variant_price, tax_address: @shipment.address, tax_rate_id: @order_item.tax_rate_id)
    substitute_order_item.item_options_id = order_item.item_options_id if order_item.engraving?
    substitute_order_item.save!
    substitute_order_item
  end

  def get_remaining_order_item
    remaining_order_item = nil
    if @quantity_to_replace < @order_item.quantity
      remaining_order_item = OrderItemTemp.new(variant: @order_item.variant, quantity: @order_item.quantity - @quantity_to_replace, price: @order_item.price, tax_address: @shipment.address, tax_rate_id: @order_item.tax_rate_id)
      remaining_order_item.save!
    end
    remaining_order_item
  end

  def get_substitution(shipment, substitute_order_item, order_item, remaining_order_item)
    Substitution.create(shipment: shipment, substitute: substitute_order_item, original: order_item, remaining_item: remaining_order_item)
  end
end
